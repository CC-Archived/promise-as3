package com.codecatalyst.promise
{
	import flash.events.IEventDispatcher;
	import flash.utils.clearInterval;
	import flash.utils.setTimeout;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.Responder;

	/**
	 * jQuery-like wrapper to Deferreds and Promises. Function used to create alias object with power 
	 * functions for using Deferred and Promises. Instead of use the OOP approach to construct and configure
	 * Deferred and Promise, you can now use jQuery-like syntax to condense your coding requirements.
	 * 
	 * NOTE: While jQuery.as could have been implemented as a Class definition instead of a Function definition.
	 *       but this implementation is very similar to that seen in jQuery.js and should be more intuitive for developers
	 * 		 with dual javascript and actionscript responsibilities.
	 * 
	 * Usage: 
	 * 
	 * var 	$ = jQuery();
	 * 
	 * 		$.wait(3000).then( function(interval) {
	 *  				
	 * 			Alert.show("Hello from the future: " + interval + " msecs later!");
	 * 				
	 * 		});
	 *
	 * @see com.codecatalyst.util.promise.Promise
	 * @see com.codecatalyst.util.promise.Deferred
	 *   
	 * @author Thomas Burleson
	 */
	public function jQuery() : Object {
		
		// Build a hashmap of named functions
		
		var $ : Object  = { 
							each : function( list:Object, iterator:Function) {
								/**
								 * Note: In AS3, Typed-Class properties cannot be enumerated this way
								 *       but this works for array and dynamic objects
								 */
								for (var key in list)
								{
									iterator.call( list[key], key, list[key] );
								}
							}, 
							
							noop : function(p) {
								return undefined;
							},
							
							/**
							 * Macro constructor used for partial applications
							 * 
							 * @see com.codecatalyst.util.promise.Callbacks
							 */
							Callbacks : function( flags:String=null ) {
										return new Callbacks( flags );
									},
							/**
							 * Macro constructor used for partial applications
							 * 
							 * @see com.codecatalyst.util.promise.Deferred
							 * @see com.codecatalyst.util.promise.jQuery#wait()
							 */
							Deferred : function( func:Function=null ) {
										return new Deferred( func );
									},
			
							/**
							 * Similar to callLater() but supports any arbitrary delay 
							 * and allows optional, additional parameters to passed [later] to the 
							 * `resolved` handler.
							 * 
							 *  $.wait( delay )
							 *  $.wait( delay, ...params )
							 *  $.wait( delay, func2Call )
							 * 	$.wait( delay, func2Call, func2Params )
							 * 
							 */
							wait : Promise.wait,
							
							/**
							 * Power macro feature to easily create deferred [delegated handling of response/fault processing]
							 * for targeted functions, AsyncTokens, HTTPService, URLLoader, RemoteObject, and generalized
							 * IEventDispatchers. 
							 * 
							 * If the target is an IEventDispatcher, this creates a Promise that adapts an 
							 * asynchronous operation which uses event-based notification:
							 * 
							 *  	watch( <IEventDispatcher>, <options> );
							 *  	watch( <IEventDispatcher>, <resultEventType> ); 
							 * 		watch( <IEventDispatcher>, <resultEventType>, <faultEventTypes[]>, );
							 *  	watch( <IEventDispatcher>, <resultEventType>, <faultEventTypes[]>, <options> );
							 * 
							 * The <options> parameter is a hashmap of optional key/value pairs:
							 * 
							 *   { 
							 * 		useCapture : <boolean>,
							 * 	    priority   : <int>,
							 * 		types 	   : {
							 * 						result 		: <string>,
							 * 						faults 		: [ <string> ],
							 * 						progress	: {
							 * 										type : <string>,
							 * 										path : <string>
							 * 				 					  }
							 * 				     },
							 * 
							 * 		// Token options used to filter only specific event instances of `type`
							 * 
							 * 		token  	   : {
							 * 						path          : <string>,
							 * 						expectedValue : *
							 *               	 }
							 *   }
							 * 
							 * 
  							 * @param args Array of optional parameters; only used when the target is an IEventDispatcher
							 * 
							 * @see com.codecatalyst.util.promise.PromiseUtil#watch()
							 */
							watch : Promise.watch,
							
							/**
							 * Alias to Promise.when() which supports 1-n PARALLEL processing promises
							 * Results are batched to single resolve(), Faults will stop the batch and immediately
							 * reject
							 * 
							 * @see com.codecatalyst.util.promise.Promise#when()
							 */
							when : Promise.when
						};
	
		return $;
	}
}