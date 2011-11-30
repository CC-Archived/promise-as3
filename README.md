# Promises for Actionscript 3

## Attention Developers

All work is currently in the [develop branch](https://github.com/CodeCatalyst/promise-as3/tree/develop)
A detailed README is also availble in the develop branch.

&nbsp;

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


