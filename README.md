# Promises for Actionscript 3


## Introduction


The repository provides a AS3 library of futures as defined by [CommonJS](http://wiki.commonjs.org/wiki/Promises). 

A promise (aka [Future](http://en.wikipedia.org/wiki/Futures_and_promises)) is an object thats acts as a proxy for a result that my not be initially known, usually because the computation of its value has not yet completed. Developers *defer* processing by returning a promise to respond later. A **promise**is essentially a read-only version of the **deferred**response.

* `new Deferred()`
    * can add callbacks
    * can be resolved or rejected
    * can **promise()**to let you know what happened  
&nbsp; 
 

* Promise (accessed via `new Deferred().promise`)
    * can add callbacks
    * Can't resolve, so you know it's legit when it does
    * Can check resolve status
    * Can cancel (*only in AS3 version*)

&nbsp;

Popularized in the [jQuery](http://ajax.googleapis.com/ajax/libs/jquery/1/jquery.js) javascript library, Deferred(s) are now available for AS3 developers. This library emulates the jQuery v1.7 feature set of futures: Deferred, Promise, and Callbacks. This library also supports two syntactical approaches familiar to either jQuery users or Actionscript/Flex developers.
 
Flex developers often use components asynchronously:

* setTimeOut()
* setInterval()
* callLater()
* Timer
* Loader
* URLLoader
* HTTPService
* RemoteObject
* WebService
* NetStream
* Socket
* NetConnection
* SharedObject

The above components, unfortunately, do not have a consistent mechanism in which developers may handle the asynchronous responses… until now! With the above components developers would use:

* addEventListener()
* Responders
* AsyncToken
* closures (aka callbacks)

## Why Deferred(s)

Now developers can employ `Deferred.as` to build promises of responses. The interface is always the same regardless of the component/mechanism used to fulfill the promise.

The biggest advantages are 

1. Consistent, intuitive API for attaching handlers to asynchronous processes
2. Ability to intercept and transform results before handlers are called
3. Ability to chain futures in sequence
4. Ability to process futures in parallel (aka batch processing)



## Using Deferred


Deferred(s) and Promise(s) can be easily created programmatically with:

    var did 	: Deferred = new Deferred();
	var promise : Promise  = dfd.promise;

    // Do some async activity. When done, mark `dfd` as resolved or rejected
	// Attach handlers to promise for completion, rejection, notification, or cancellation

Or developers can use the shorthand, scoped approach:

	var promise = new Deferred( function(dfd) {
						// Do some async activity. 
						// When done, mark `dfd` as resolved or rejected
				  }).promise;
    
	// Attach handlers to promise for completion, rejection, notification, or cancellation

&nbsp;

Developers can attach handlers to Deferred(s) or Promise(s) instances using:

* instance.**done**( doneFunc )
* instance.**fail**( failFunc)
* instance.**progress**( progressFunc )
* instance.**always**( func )
* instance.**then**( doneFunc, failFunc, progressFunc, cancelFunc )
* instance.**pipe**( doneFunc, failFunc, progressFunc, cancelFunc )

&nbsp;

These callback functions (aka handlers ) will be invoked upon the following Deferred/Promise instance triggers:

* instance.**resolve**()	
* instance.**reject**()		
* instance.**cancel**()		
* instance.**notify**()




## Use jQuery.as 


This library contains a jQuery wrapper class that enables developers to easily instantiate and use deferreds. With `jQuery.as`, developers now have full support for the succinct syntax offered within jQuery Javascript. Simply use:

    import com.codecatalyst.promise.jQuery;

    var $ = jQuery();

Then instead of `new Deferred()` developers can simply use `$.Deferred()` with a constructor handler. So code like:

    var onResult  : Function   = function (event:ResultEvent){  
                                  /* ... handle async response here */   
                                 },
        onFault   : Function   = function (event:FaulttEvent){  
                                  /* ... handle async error here    */   
                                  };

	var dfd       : Deferred   = new Deferred(),
        token     : AsynToken  = employeeSevice.logEmployee(userID),
        responder : Responder  = new Responder(dfd.resolve,dfd.reject);        

        token.addResponder(responder);
        dfd.promise.then( onResult, onFault );


becomes:

    $.Deferred( function(dfd) {

        var token  = employeeSevice.logEmployee(userID);
            token.addResponder( new Responder( dfd.resolve, dfd.reject) );

    }).promise
      .then( onResult, onFault );

This leads to very concise, clear, maintainable code for developers. Other macro features include `$.wait()`, `$.when()`, and `$.watch()`.

### $.wait()

AS3 developers now longer need to use `callLater()`, `setInterval()`, or `Timer.as` to asynchronously defer code execution for 1 frame or specific milliseconds.

    $.wait(45, function(){
        // … run the async code here; after 45 msecs
    })   

or 

    // Invoke callback with two (2) arguments

    $.wait(45, function(a,b){
        // … run the async code here; after 45 msecs
    },valueA, valueB);   



### $.watch()

$.watch(<target>) is an alias to `Promise::watch()`; which in turn is a special, power feature that will create a future for a specified target object. The target instances may be an AsyncToken, EventDispatchers, Responders, or function callbacks.

$.watch() will work with 

* URLLoader
* HTTPService
* RemoteObject
* WebService
* NetStream
* Socket
* NetConnection
* SharedObject
* or your own custom, async component

#### 
**1) Watching an AsyncToken**

Let's consider an example RPC call loadEmployee() that returns an `AsyncToken` and a future `ResultEvent`. In this scenario, the developer wants to call `loadEmployee(<userID>)` and update a data model with the employee information once loaded:

    public function loadUserDetails(userID:String):void {

        var token    : AsyncToken = employeeService.loadEmployee(userID);
        var promise  : Promise    = $.watch(token)
                                     .pipe( function(event:ResultEvent) {
                                        return event.result as EmployeeVO;
                                     })
                                     .done( function(employee:EmployeeVO) {
                                       model.addUser(employee);                               
                                     });
    }
    
With `$.watch()` we can easily watch for the ResultEvent, extract the employee valueObject using `pipe()` interception, and then update our data model inside the `done()` handler.


#### 
**2) Watching an EventDispatcher**

Let's consider a scenario in which we are loading an external XML data file. Consider the `URLLoader` example below:

 		/**
		 * Use AS3 Deferred(s), we can easily `watch` a URLLoader
		 * for a promised response. 
		 *  
		 * Load an external XML data file and save to our model.
		 * Watch loader instance and handle progress and completion events
		 */
		public function loadCountries(url:String):void {
  
		    // Notice use of IIFE-like wrapper to create reference to $ macro
		    var $       : Object     = jQuery();
    
		    var loader  : URLLoader  = new URLLoader();
		    var promise : Promise    = $.watch( loader, 
		                                        Event.COMPLETE, 
		                                        null, 
		                                        Event.PROGRESS);
    
		         loader.load( new URLRequest( url ) );

		         return promise.then( function (event:Event){
		                                // Result handler called for URLLoader completes event
		                                // Use closure scope to access `loader` instance

		                                model.data = loader.data;
		                              }, 
		                              null, 
		                              function (event:Event){
		                                // Progress handler called when data is received 
		                                // as the download operation progresses.

		                                // Update progress bar by 25% complete...
		                            });
		}
Developers should note that the $.watch() also removes listeners and clears memory references when the future  is finished, rejected, or cancelled. This means that GC is transparently supported. 

#### 
**More…**

*  For details and examples on using alias $.wait(), please refer to the wiki documentation [Promise::watch()]().
*  For details on uses of `pipe()` to intercept responses or sequentially chain asynchronous operations, please refer to the wiki documentation [Promise::pipe()]().


## Testing & Builds

**Use FlexUnit4 and FlashBuilder 4.6**

FlexUnit4 tests are continually updated to test the Promise-AS3 classes. Additionally the tests include ports of the same QUnit jQuery tests used to test the Javascript Deferreds. See:

* [TestjQuery.as](https://github.com/CodeCatalyst/promise-as3/blob/develop/test/com/codecatalyst/promise/tests/TestjQuery.as) - ported tests for Deferred and Promise
* [TestCallbacks.as](https://github.com/CodeCatalyst/promise-as3/blob/develop/test/com/codecatalyst/promise/tests/TestCallbacks.as) - ported tests for Callbacks

**Use Ant**

An [build.xml](https://github.com/CodeCatalyst/promise-as3/blob/develop/build.xml) script is provided that allows the Promise-AS3 library to be compiled and compressed for production use. The default build in the ANT script will not include any compiled FlexUnit tests.

  

## Learning Resources
&nbsp; 

* [Crockford on JavaScript - Act III: Function the Ultimate](http://www.youtube.com/watch?feature=player_detailpage&v=ya4UHuXNygM#t=2529s)
* [Deferreds into jQuery](http://danheberden.com/presentations/jqsummit-deferreds-in-jquery/)
* [Deferreds - Putting Laziness to Work](http://danheberden.com/presentations/deferreds-putting-laziness-to-work/#1)
* [Creating Responsive Applications Using jQuery Deferred and Promises](http://msdn.microsoft.com/en-us/scriptjunkie/gg723713.aspx)
* [The Power Of Closures - Deferred Object Bindings In jQuery](http://www.bennadel.com/blog/2125-The-Power-Of-Closures-Deferred-Object-Bindings-In-jQuery-1-5.htm)
* [Fun with jQuery Deferred](http://intridea.com/2011/2/8/fun-with-jquery-deferred?blog=company)
* [Understanding jQuery.Deferred and Promise](http://joseoncode.com/2011/09/26/a-walkthrough-jquery-deferred-and-promise/)
* [A Graphical Explanation Of Javascript Closures In A jQuery Context](http://www.bennadel.com/blog/1482-A-Graphical-Explanation-Of-Javascript-Closures-In-A-jQuery-Context.htm)
* [From callbacks... to $.Deferred... to $.Callbacks](http://demo.creative-area.net/jqcon2011-boston/#1)
* [Using Promises to bind Button clicks](http://jsfiddle.net/ThomasBurleson/RTLr6/)
* [Demystifying jQuery 1.7′s $.Callbacks](http://addyosmani.com/blog/jquery-1-7s-callbacks-feature-demystified/)
* [when.js](https://github.com/briancavalier/when.js) - standalone, Promise/A implementation.