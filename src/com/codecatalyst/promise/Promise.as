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

	/**
	 * Promise.
	 * 
	 * An object that acts as a proxy for observing deferred result, fault or progress state from a synchronous or asynchronous operation.
	 * 
	 * Inspired by jQuery's Promise implementation.
	 * 
	 * @author John Yanarella
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
		public function get unfulfilled():Boolean
		{
			return deferred.pending;
		}
		
		[Bindable( "stateChanged" )]
		/**
		 * Indicates this Promise has been fulfilled.
		 */
		public function get fulfilled():Boolean
		{
			return deferred.succeeded;
		}
		
		[Bindable( "stateChanged" )]
		/**
		 * Indicates this Promise has failed.
		 */
		public function get failed():Boolean
		{
			return deferred.failed;
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
		public function get progress():*
		{
			return deferred.progress;
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
		 * Constructor.
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

			// Special handling for when an Array of Promises is specified instead of variable numbe of Promise arguments.
			if ( ( promises.length == 1 ) && ( promises[ 0 ] is Array ) )
				promises = promises[ 0 ];
			
			// Ensure the promises Array is populated with Promises.
			var parameterCount:int = promises.length;
			for ( var parameterIndex:int = 0; parameterIndex <  parameterCount; parameterIndex++ )
			{
				var parameter:* = promises[ parameterIndex ];
				
				switch ( parameter.constructor )
				{
					case Promise:
						break;
					
					case Deferred:
						// Replace the promises Array element with the associated Promise for the specified Deferred value.
						promises[ parameterIndex ] = parameter.promise;
						break;
						
					default:
						// Create a new Deferred resolved with the specified parameter value, and replace the promises Array element with the associated Promise.
						promises[ parameterIndex ] = new Deferred().resolve( parameter ).promise;
						break;
				}
			}
			
			var pendingPromiseCount:int = promises.length;
			
			var progressValues:Array = new Array( pendingPromiseCount );
			var resultValues:Array   = new Array( pendingPromiseCount );
			
			for each ( var promise:Promise in promises )
			{
				promise
					.then(
						function ( promise:Promise, result:* ):void
						{
							resultValues[ promises.indexOf( promise ) ] = result;
							
							pendingPromiseCount--;
							if ( pendingPromiseCount == 0 )
								deferred.resolve( resultValues );
						},
						function ( error:* ):void
						{
							deferred.reject( error );
						},
						function ( promise:Promise, update:* ):void
						{
							progressValues[ promises.indexOf( promise ) ] = update;
							
							deferred.update( progressValues );
						},
						function ( reason:* ):void
						{
							deferred.cancel( reason );
						}
					);
			}
			
			return deferred.promise;
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
		 * Utility method to filter and/or chain Deferreds.
		 */
		public function pipe( resultCallback:Function, errorCallback:Function = null ):Promise
		{
			return deferred.pipe( resultCallback, errorCallback );
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
		 * Cancel this Promise.
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