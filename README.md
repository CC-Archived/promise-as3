# Promises for Actionscript 3

## <span style="color:#AA0000">Attention Developers</span>

All work is currently in the [develop branch](https://github.com/CodeCatalyst/promise-as3/tree/develop) <br/>
A detailed README is also availble in the develop branch.


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
