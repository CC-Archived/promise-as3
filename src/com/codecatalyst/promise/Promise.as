////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2011 CodeCatalyst, LLC - http://www.codecatalyst.com/
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.	
////////////////////////////////////////////////////////////////////////////////

package com.codecatalyst.promise
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.clearInterval;
	import flash.utils.setTimeout;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.Responder;

	/**
	 * Promise.
	 * 
	 * An object that acts as a proxy for observing deferred result, fault or progress state from a synchronous or asynchronous operation.
	 * 
	 * Inspired by jQuery's Promise implementation.
	 * 
	 * @author John Yanarella
	 * @author Thomas Burleson  
	 */
	public class Promise extends EventDispatcher
	{
		// ========================================
		// Public properties
		// ========================================		
		
		[Bindable( "stateChanged" )]
		/**
		 * Indicates this Promise has not yet been fulfilled.
		 */
		public function get pending():Boolean
		{
			return deferred.pending;
		}
		
		[Bindable( "stateChanged" )]
		/**
		 * Indicates this Promise has been fulfilled.
		 */
		public function get resolved():Boolean
		{
			return deferred.resolved;
		}
		
		[Bindable( "stateChanged" )]
		/**
		 * Indicates this Promise has failed.
		 */
		public function get rejected():Boolean
		{
			return deferred.rejected;
		}
		
		[Bindable( "stateChanged" )]
		/**
		 * Indicates this Promise has been cancelled.
		 */
		public function get cancelled():Boolean
		{
			return deferred.cancelled;
		}
		
		[Bindable( "stateChanged" )]
		/**
		 * Progress supplied when this Promise was updated.
		 */
		public function get status():*
		{
			return deferred.status;
		}
		
		[Bindable( "stateChanged" )]
		/**
		 * Result supplied when this Promise was fulfilled.
		 */
		public function get result():*
		{
			return deferred.result;
		}
		
		[Bindable( "stateChanged" )]
		/**
		 * Error supplied when this Promise failed.
		 */
		public function get error():*
		{
			return deferred.error;
		}
		
		[Bindable( "stateChanged" )]
		/**
		 * Reason supplied when this Promise failed.
		 */
		public function get reason():*
		{
			return deferred.reason;
		}
		
		// ========================================
		// Protected properties
		// ========================================
		
		/**
		 * Deferred operation for which this is a Promise.
		 */
		protected var deferred:Deferred = null;
		
		// ========================================
		// Constructor
		// ========================================
		
		/**
		 * Constructor should only be called/instantiated by a Deferred constructor
		 */
		public function Promise( deferred:Deferred )
		{
			super();
			
			this.deferred = deferred;
			
			deferred.addEventListener( Deferred.STATE_CHANGED, deferred_stateChangeHandler, false, 0, true );
		}
		
		// ========================================
		// Public static methods
		// ========================================		
		
		/**
		 * Utility method to create a new Promise based on one or more Promises (i.e. parallel chaining).
		 * 
		 * NOTE: Result and progress handlers added to this new Promise will be passed an Array of aggregated result or progress values.
		 */
		public static function when( ...promises ):Promise
		{
			var deferred:Deferred = new Deferred();
			
			// In the scenario where instance.when() is called with NOTHING to watch
			if (promises.length < 1)  {
				deferred.resolve();
			}


			// Special handling for when an Array of Promises is specified instead of variable numbe of Promise arguments.
			if ( ( promises.length == 1 ) && ( promises[ 0 ] is Array ) )
				promises = promises[ 0 ];
			
			// Ensure the promises Array is populated with Promises.
			var parameterCount:int = promises ? promises.length : 0;
			for ( var parameterIndex:int = 0; parameterIndex <  parameterCount; parameterIndex++ )
			{
				var parameter:* = promises[ parameterIndex ];
				
				if (parameter == null) 
				{
					promises[ parameterIndex ] = new Deferred().resolve(null).promise;
					
				} else {
					
					switch ( parameter.constructor )
					{
						case Promise:
							break;
						
						case Deferred:
							// Replace the promises Array element with the associated Promise for the specified Deferred value.
							promises[ parameterIndex ] = parameter.promise;
							break;
							
						default:
							// Create a new Deferred resolved with the specified parameter value, 
							// and replace the promises Array element with the associated Promise.
							
							var func : Function = parameter as Function;
							
							promises[ parameterIndex ] = new Deferred( func ).resolve( func ? null : parameter).promise;
							break;
					}
				}
			}
			
			var pendingPromiseCount:int = promises.length;
			
			var progressValues:Array = new Array( pendingPromiseCount );
			var resultValues:Array   = new Array( pendingPromiseCount );

				/**
				 * Use closure to manage promise reference in the then() handlers
				 */
				function _watchPromise(promise) : void {
					promise.then(
								// All promises must resolve() before the when() resolves
						
								function ( result:* ):void {
									resultValues[ promises.indexOf( promise ) ] = result;
									
									pendingPromiseCount--;
									if ( pendingPromiseCount == 0 )
										deferred.resolve.apply(deferred, resultValues );
								},
								
								// Any promise reject(), rejects the when()
								
								function ( error:* ):void {
									deferred.reject( error );
								},
								
								function ( promise:Promise, update:* ):void {
									progressValues[ promises.indexOf( promise ) ] = update;
									
									deferred.notify.apply(deferred, progressValues );
								},
								
								// Any promise cancel(), cancels the when()
								
								function ( reason:* ):void {
									deferred.cancel( reason );
								}
							);
				};
				
			
			for each ( var promise:Promise in promises )
			{
				_watchPromise(promise);
			}
			
			return deferred.promise;
		}
		
		
		/**
		 * Similar to the callLater() function but supports any arbitrary delay 
		 * and allows optional, additional parameters to passed [later] to the 
		 * resolved handler [assigned via .done() or .then()].
		 *  
		 * A special configuration allows the 1st optional parameter to be a function
		 * reference so the wait(delay,function(){...}) syntax can be easily used.
		 * 
		 * Here are the possible call options:
		 * 
		 *   wait( delay )
		 *   wait( delay, ...params )
		 *   wait( delay, func2Call )
		 * 	 wait( delay, func2Call, ...func2Params )
		 * 
		 * @param delay Number of milliseconds to wait before resolving/projecting the promise; 
		 *              Default value === 30 msecs
		 *
		 * @param args  Optional listing of parameters 
		 */
		public static function wait ( delay:uint=30, ...args ) : Promise {
			
				/**
				 * If the first variable param is a Function reference, then auto-call
				 * that function with/without any subsequent optional params 
				 */
				function doInlineCallback():* {
					var func 	: Function = args.length ? args[0] as Function : null,
						result  : * 	   = null;
					
					if (func != null) {
						// 1) Remove function element,
						// 2) Call function, save response, and
						// 3) Clear arguments
						
						args.shift();
						
						result = func.apply(null, args);
						args   = [ ];
					}
					
					return result;
				}
				
			return new Deferred( function(dfd:Deferred) : void {
				var timer:uint = setTimeout( function():void{
					clearInterval(timer);

					// Call the specified function (if any)
					
					var response : * = doInlineCallback();
					
					// Since resolve() expects a resultVal == *, we use the .call() invocation
					
					dfd.resolve.apply( dfd, response ? [response] : args.length ? args : null );
					
				}, delay );
				
			}).promise;
		}
		
		
		/**
		 * Power feature to easily create deferred [delegated handling of response/fault processing]
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
		public static function watch (target:Object, ...args):Promise {
			switch (target.constructor) 
			{
				case Promise    :
					return Promise.when( target );
					
				case Function   :
					return new Deferred( function(dfd) {
								var results = Function(target).apply(null,args);
								
								// Could be a Promise-generator or a `normal` function
								
								if (results is Promise) 
								{
									Promise(results)
										.pipe( function(value) { 
											return dfd.resolve(value); 
										});
										
								} else {
									dfd.resolve( results );
								}
								
							}).promise;
					
					//return  new Deferred( target as Function ).resolve( args ).promise;
					
				case AsyncToken :
					return  new Deferred( function( dfd ) {
								var responder = new Responder( dfd.resolve, dfd.reject );
								AsyncToken(target).addResponder( responder );
							}).promise;
					
				default        :
					if ( target is IEventDispatcher )
					{
						return PromiseUtil.watch.apply(null, [target].concat(args));
					}
			}
			
			// Return empty, resolved promise
			
			return new Deferred( function(dfd:Deferred){ 
						dfd.resolve( [target].concat(args) ); 
					}).promise;
		}		
		
		// ========================================
		// Public methods
		// ========================================
		
		/**
		 * Register callbacks to be called when this Promise is resolved or rejected.
		 */
		public function then( resultCallback:Function, errorCallback:Function = null, progressCallback:Function = null, cancelCallback:Function = null ):Promise
		{
			return deferred.then( resultCallback, errorCallback, progressCallback, cancelCallback ).promise;
		}
		
		/**
		 * Registers a callback to be called when this Promise is either resolved or rejected.
		 */
		public function always( alwaysCallback:Function ):Promise
		{
			return deferred.always( alwaysCallback ).promise;
		}
		
		/**
		 * Alias to Deferred.then().
		 * More intuitive with syntax:  $.when( ... ).done( ... )
		 * 
		 * @param resultCallback Function to be called when the Promise resolves.
		 */
		public function done ( resultCallback : Function ):Promise 
		{
			return deferred.then( resultCallback ).promise;
		}

		/**
		 * Alias to Deferred.fail(); match jQuery API
		 * 
		 * @param resultCallback Function to be called when the Promise resolves.
		 */
		public function fail ( resultCallback : Function ):Promise 
		{
			return deferred.fail( resultCallback ).promise;
		}

		/**
		 * Registers a callback to be called when this Promise is updated.
		 */
		public function progress( progressCallback:Function ):Promise
		{
			return deferred.progress( progressCallback ).promise;
		}
		
		
		/**
		 * Utility method to filter and/or chain Deferreds.
		 */
		public function pipe( resultCallback:Function, errorCallback:Function = null, progressCallback:Function=null ):Promise
		{
			return deferred.pipe( resultCallback, errorCallback, progressCallback );
		}
		
		
		/**
		 * Registers a callback to be called when this Promise is updated.
		 */
		public function onProgress( progressCallback:Function ):Promise
		{
			return deferred.onProgress( progressCallback ).promise;
		}
		
		/**
		 * Registers a callback to be called when this Promise is resolved.
		 */
		public function onResult( resultCallback:Function ):Promise
		{
			return deferred.onResult( resultCallback ).promise;
		}
		
		/**
		 * Registers a callback to be called when this Promise is rejected.
		 */
		public function onError( errorCallback:Function ):Promise
		{
			return deferred.onError( errorCallback ).promise;
		}
		
		/**
		 * Registers a callback to be called when this Promise is cancelled.
		 */
		public function onCancel( cancelCallback:Function ):Promise
		{
			return deferred.onCancel( cancelCallback ).promise;
		}
		
		/**
		 * Special feature of this read-only promise:
		 * Ability to `cancel` this pending Promise.
		 * 
		 */
		public function cancel( reason:* = null ):void
		{
			deferred.cancel( reason );
		}
		
		// ========================================
		// Protected methods
		// ========================================
		
		/**
		 * Handle and redispatch state change notifications from the Deferred operation.
		 */
		protected function deferred_stateChangeHandler( event:Event ):void
		{
			dispatchEvent( event.clone() );
		}
	}
}