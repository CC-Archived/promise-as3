<img src="https://raw.github.com/CodeCatalyst/promise-as3/master/promise-as3-logo.png" width="580" height="115">
<a href="https://github.com/promises-aplus/promises-spec"><img src="http://promises-aplus.github.com/promises-spec/assets/logo-small.png" align="right" /></a>

## About

promise-as3 is an ActionScript 3.0 implementation of the [Promises/A+ Specification](https://github.com/promises-aplus/promises-spec).  Its implementation is derived from the [promise.coffee](https://github.com/CodeCatalyst/promise.coffee) object oriented [CoffeeScript](http://coffeescript.org/) reference implementation.

It is fully asynchronous, ensuring that the `onFulfilled` and `onRejected` callbacks are not executed in the same turn of the event loop as the call to `then()` with which they were registered.

It supports foreign promises returned by callbacks as long as they support the standard Promise `then()` method signature.

## API

Create a deferred:

	import com.codecatalyst.promise.Deferred;
	
	...
	
	var deferred:Deferred = new Deferred();

Resolve that deferred:
	
	deferred.resolve( value );

Or, reject that deferred:

	deferred.reject( reason );

Obtain the promise linked to that deferred to pass to external consumers:

	import com.codecatalyst.promise.Promise;
	
	...
	
	var promise:Promise = deferred.promise;

Add (optional) handlers to that promise:

	promise.then( onFulfilled, onRejected );

Immediate values, foreign Promises (i.e. a Promise from another Promises/A implementation), and AsyncTokens can be adapted using the Promise.when() helper method.

To adapt an immediate value:

	var promise:Promise = Promise.when( 123 );

To adapt a foreign Promise:

	var promise:Promise = Promise.when( foreignPromise );

To adapt an AsyncToken:

	var token:AsyncToken = ...
	
	...
	
	var promise:Promise = Promise.when( token );


## Internal Anatomy

This implementation decomposes Promise functionality into three classes:

### Promise

Promises represent a future value; i.e., a value that may not yet be available.

A Promise's `then()` method is used to specify `onFulfilled` and `onRejected` callbacks that will be notified when the future value becomes available.  Those callbacks can subsequently transform the value that was resolved or the reason that was rejected.  Each call to `then()` returns a new Promise of that transformed value; i.e., a Promise that is resolved with the callback return value or rejected with any error thrown by the callback.

### Deferred

A Deferred is typically used within the body of a function that performs an asynchronous operation.  When that operation succeeds, the Deferred should be resolved; if that operation fails, the Deferred should be rejected.

Once a Deferred has been resolved or rejected, it is considered to be complete and subsequent calls to `resolve()` or `reject()` are ignored.

Deferreds are the mechanism used to create new Promises.  A Deferred has a single associated Promise that can be safely returned to external consumers to ensure they do not interfere with the resolution or rejection of the deferred operation.

### Resolver

Resolvers are used internally by Deferreds and Promises to capture and notify callbacks, process callback return values and propogate resolution or rejection to chained Resolvers.

Developers never directly interact with a Resolver.

A Resolver captures a pair of optional `onResolved` and `onRejected` callbacks and has an associated Promise.  That Promise delegates its `then()` calls to the Resolver's `then()` method, which creates a new Resolver and schedules its delayed addition as a chained Resolver.

Each Deferred has an associated Resolver.  A Deferred delegates `resolve()` and `reject()` calls to that Resolver's `resolve()` and `reject()` methods.  The Resolver processes the resolution value and rejection reason, and propogates the processed resolution value or rejection reason to any chained Resolvers it may have created in response to `then()` calls.  Once a chained Resolver has been notified, it is cleared out of the set of chained Resolvers and will not be notified again.

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
* [Jason Barry](http://dribbble.com/artifactdesign), who designed the promise-as3 logo.

## License

Copyright (c) 2013 [CodeCatalyst, LLC](http://www.codecatalyst.com/)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.