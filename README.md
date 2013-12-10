<img src="https://raw.github.com/CodeCatalyst/promise-as3/master/promise-as3-logo.png" width="580" height="115">
<a href="https://github.com/promises-aplus/promises-spec"><img src="http://promises-aplus.github.com/promises-spec/assets/logo-small.png" align="right" /></a>

## About

promise-as3 is an ActionScript 3.0 implementation of the [Promises/A+ Specification](https://github.com/promises-aplus/promises-spec).  Its implementation is derived from the [promise.coffee](https://github.com/CodeCatalyst/promise.coffee) object oriented [CoffeeScript](http://coffeescript.org/) reference implementation.

It is fully asynchronous, ensuring that the `onFulfilled` and `onRejected` callbacks are not executed in the same turn of the event loop as the call to `then()` with which they were registered.

It supports foreign promises returned by callbacks as long as they support the standard Promise `then()` method signature.

## Internal Anatomy

This implementation decomposes Promise functionality into four classes:

### Promise

Promises represent a future value; i.e., a value that may not yet be available.

A Promise's `then()` method is used to specify `onFulfilled` and `onRejected` callbacks that will be notified when the future value becomes available.  Those callbacks can subsequently transform the value that was fulfilled or the reason that was rejected.  Each call to `then()` returns a new Promise of that transformed value; i.e., a Promise that is fulfilled with the callback return value or rejected with any error thrown by the callback.

The Promise class also provides helper methods that build on the capabilities of the `then()` method, including: 

* `otherwise()` - shorthand for adding an `onRejected` callback;
* `always()` - adds an `onCompleted` callback, similar to `finally` in a `try..catch..finally` block;
* `done()` - terminates a Promise chain, rethrowing any unhandled rejections as Errors;
* `cancel()` - a specialized rejection initiated from the Promise (consumer) rather than the Deferred (producer); and
* `log()` - logs the resolution or rejection of a Promise, with an optional category and identifier.

### Deferred

A Deferred is typically used within the body of a function that performs an asynchronous operation.  When that operation succeeds, the Deferred should be resolved; if that operation fails, the Deferred should be rejected.

A Deferred is resolved by calling its `resolve()` method with an optional value, and is rejected by calling its `reject()` method with an optional reason.  Once a Deferred has been fulfilled or rejected, it is considered to be complete and subsequent calls to `resolve()` or `reject()` are ignored.

Deferreds are the mechanism used to create new Promises.  A Deferred has a single associated Promise that can be safely returned to external consumers to ensure they do not interfere with the resolution or rejection of the deferred operation.

### Resolver

Resolvers are used internally by Deferreds to create, resolve and reject Promises, and to propagate fulfillment and rejection.

Developers never directly interact with a Resolver.

Each Deferred has an associated Resolver, and each Resolver has an associated Promise.  A Deferred delegates `resolve()` and `reject()` calls to its Resolver's `resolve()` and `reject()` methods.  A Promise delegates `then()` calls to its Resolver's `then()` method.  In this way, access to Resolver operations are divided between producer (Deferred) and consumer (Promise) roles.

When a Resolver's `resolve()` method is called, it fulfills with the optionally specified value.  If `resolve()` is called with a then-able (i.e. a Function or Object with a `then()` function, such as another Promise) it assimilates the then-able's result; the Resolver provides its own `resolve()` and `reject()` methods as the `onFulfilled` or `onRejected` arguments in a call to that then-able's `then()` function.  If an error is thrown while calling the then-able's `then()` function (prior to any call back to the specified `resolve()` or `reject()` methods), the Resolver rejects with that error.  If a Resolver's `resolve()` method is called with its own Promise, it rejects with a `TypeError`.

When a Resolver's `reject()` method is called, it rejects with the optionally specified reason.

Each time a Resolver's `then()` method is called, it captures a pair of optional `onFulfilled` and `onRejected` callbacks and returns a Promise of the Resolver's future value as transformed by those callbacks.

### Consequence

Consequences are used internally by Resolvers to capture and notify callbacks, and propagate their transformed results as fulfillment or rejection.

Developers never directly interact with a Consequence.

A Consequence forms a chain between two Resolvers, where the result of the first Resolver is transformed by the corresponding callback before being applied to the second Resolver.

Each time a Resolver's `then()` method is called, it creates a new Consequence that will be triggered once its originating Resolver has been fulfilled or rejected.  A Consequence captures a pair of optional `onFulfilled` and `onRejected` callbacks. 

Each Consequence has its own Resolver (which in turn has a Promise) that is resolved or rejected when the Consequence is triggered.  When a Consequence is triggered by its originating Resolver, it calls the corresponding callback and propagates the transformed result to its own Resolver; resolved with the callback return value or rejected with any error thrown by the callback.

## API

### Creating, Resolving and Rejecting Promises

Create a deferred:

```ActionScript
import com.codecatalyst.promise.Deferred;

...
	
var deferred:Deferred = new Deferred();
```

Resolve that deferred:

```ActionScript
deferred.resolve( value );
```

Or, reject that deferred:

```ActionScript
deferred.reject( reason );
```

Obtain the promise linked to that deferred to pass to external consumers:

```ActionScript
import com.codecatalyst.promise.Promise;

...

var promise:Promise = deferred.promise;
```

### Adding Callbacks, Chaining and Transformation

Add (optional) `onFullfilled` and `onRejected` callbacks to that promise:

```ActionScript
promise.then( onFulfilled, onRejected );
```
	
Those callbacks can subsequently transform the value that was fulfilled or the reason that was rejected. Each call to `then()` returns a new Promise of that transformed value; i.e., a Promise that is fulfilled with the callback return value or rejected with any error thrown by the callback.

Or, add an `onRejected` callback using the shorthand method:

```ActionScript
promise.otherwise( onRejected );
```
	
which is equivalent to:

```ActionScript
promise.then( null, onRejected );
```

Because `then()` returns a new Promise, these statements can be chained:

```ActionScript
promise
	.then( parseData )
	.then( populateUI )
	.otherwise( recover );
```

Add an `onCompleted` callback that is executed regardless of whether the Promise is resolved or rejected:

```ActionScript
promise
	.then( parseData )
	.then( populateUI )
	.otherwise( recover )
	.always( cleanup );
```

`always()` is similar to `finally` in a `try..catch..finally` block.

### Cancellation

Cancellation is a specialized form of rejection, one which can be initiated from the Promise (consumer) rather than the Deferred (producer). If a Promise is still pending, calling its `cancel()` method triggers a rejection with a `CancellationError` that will propagate to any Promises originating from that Promise.

**NOTE:** Cancellation only propagates to Promises that branch from the target Promise. It does not traverse back up to parent branches, as this would reject nodes from which other Promises may have branched, causing unintended side-effects.

### Unhandled Rejections

One of the pitfalls of interacting with Promise-based APIs is the tendency for important errors to be silently swallowed unless an explicit rejection callback is specified.

For example:

```ActionScript
promise
	.then( function () {
		// logic in your callback throws an error and it is interpreted as a rejection.
		throw new Error( 'Boom!' );
	});

// The error is silently swallowed.
```

This problem can be addressed by terminating the Promise chain with the `done()` method:

```ActionScript
promise
	.then( function () {
		// logic in your callback throws an error and it is interpreted as a rejection.
		throw new Error( 'Boom!' );
	})
	.done();

// The error is thrown on the next tick of the event loop.
```

The `done()` method ensures that any unhandled rejections are rethrown as Errors.

**NOTE:** The `done()` method should only be used by a consumer of a Promise-returning API at the terminating node of a Promise chain. A Promise-returning API should never use `done()` internally for a Promise it intends to return to a consumer; otherwise, that Promise's rejection will be thrown as an RTE and will not actually be propagated to consumers.

### Logging

The `log()` method provides a simple way to programmatically introduce logging within a Promise chain.

```ActionScript
var category:String = "DataLoader";

dataService
	.load( id )
	.log( category )
	.then( parseData )
	.log( category, "Data parsing" )
	.then( populateUI )
	.log( category, "UI population" );
```

The optional category and identifier are intended to be incorporated into the resulting log entry.

Ex.

```
[DEBUG] DataLoader: Promise resolved with value: <value>
[DEBUG] DataLoader: Data parsing resolved with value: <value>
[ERROR] DataLoader: UI population rejected with reason: <reason>
```

The Promise class can be configured with a custom logger function with the following function signature:

```ActionScript
function log( category:String, level:int, message:String, ...parameters ):void {
	// ...
}
```

Custom logger functions can be used to integrate with logging frameworks.

promise-as3 includes to example custom logger functions:

`TraceLogger` is a custom logger function that logs messages via `trace()`.

To register this logger:

```ActionScript
import com.codecatalyst.promise.logger.TraceLogger;

...

// This only needs to be done once within your application.
Promise.registerLogger(TraceLogger.log);
```

`FlexLogger` is a custom logger function that logs messages via Flex's `mx.logging.Log`.

```ActionScript
import com.codecatalyst.promise.logger.FlexLogger;

...

// This only needs to be done once within your application.
Promise.registerLogger(FlexLogger.log);
```

Multiple custom logger functions can be registered.  Loggers can be unregistered using the `unregisterLogger()` method:

```ActionScript
Promise.unregisterLogger(TraceLogger.log);
// or
Promise.unregisterLogger(FlexLogger.log);
```

### Adapting Immediate Values, Promises and AsyncTokens

Immediate values, foreign Promises (i.e. a Promise from another Promises/A implementation), and AsyncTokens can be adapted using the Promise.when() helper method.

To adapt an immediate value:

```ActionScript
var promise:Promise = Promise.when( 123 );
```

To adapt a foreign Promise:

```ActionScript
var promise:Promise = Promise.when( foreignPromise );
```

To adapt an AsyncToken:

```ActionScript
import com.codecatalyst.promise.adapters.AsyncTokenAdapter;
	
...

// NOTE: Only need to do this once for the entire application.
Promise.registerAdapter( AsyncTokenAdapter.adapt );

var token:AsyncToken = ...

var promise:Promise = Promise.when( token );
```

## Reference and Reading

* [Common JS Promises/A Specification](http://wiki.commonjs.org/wiki/Promises/A)
* [Promises/A+ Specification](https://github.com/promises-aplus/promises-spec)
* [You're Missing the Point of Promises](https://gist.github.com/3889970)

## Acknowledgements

* [Kris Zyp](https://github.com/kriszyp), who proposed the original [Common JS Promises/A Specification](http://wiki.commonjs.org/wiki/Promises/A) and created [node-promise](https://github.com/kriszyp/node-promise) and [promised-io](https://github.com/kriszyp/promised-io);
* [Domenic Denicola](https://github.com/domenic) for the [Promises/A+ Specification](https://github.com/promises-aplus/promises-spec) and [Promises/A+ Compliance Test Suite](https://github.com/promises-aplus/promises-tests), and for his work with:
* [Kris Kowal](https://github.com/kriskowal), who created [q](https://github.com/kriskowal/q), a JavaScript promise library that pioneered many of the practices now codified in the [Promises/A+ Specification](https://github.com/promises-aplus/promises-spec);
* [Brian Cavalier](https://github.com/briancavalier) for his contributions to the [Promises/A+ Specification](https://github.com/promises-aplus/promises-spec) and [Promises/A+ Compliance Test Suite](https://github.com/promises-aplus/promises-tests), and the inspiration that [avow.js](https://github.com/briancavalier/avow) and [when.js](https://github.com/cujojs/when) (with [John Hann](https://github.com/unscriptable)) and [past GitHub issue discussions](https://github.com/cujojs/when/issues/60) have provided;
* [Shaun Smith](https://github.com/darscan), who wrote [a similar AS3 port](https://gist.github.com/4519372) of promise.coffee;
* [Yehor Lvivski](http://lvivski.com/), whose [Davy Jones](https://github.com/lvivski/davy) Promises/A+ implementation and our discussion around optimizing its performance inspired improvements to [promise.coffee](https://github.com/CodeCatalyst/promise.coffee) and promise-as3's implementation; and
* [Jason Barry](http://dribbble.com/artifactdesign), who designed the promise-as3 logo.

## License

Copyright (c) 2013 [CodeCatalyst, LLC](http://www.codecatalyst.com/)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.