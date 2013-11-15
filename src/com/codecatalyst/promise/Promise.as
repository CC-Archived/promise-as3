////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2013 CodeCatalyst, LLC - http://www.codecatalyst.com/
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
	import com.codecatalyst.promise.logger.LogLevel;
	import com.codecatalyst.util.nextTick;

	/**
	 * Promises represent a future value; i.e., a value that may not yet be available.
	 */
	public class Promise
	{
		// ========================================
		// Public static methods
		// ========================================

		/**
		 * Returns a new Promise of the specified value, which may be an
		 * immediate value, a Promise, or a foreign Promise (i.e. Promises 
		 * from another Promises/A implementation).
		 * 
		 * Additionally, the specified value can be adapted into a Promise
		 * through the use of custom adapters.
		 * 
		 * @see #registerAdapter()
		 * @see #unregisterAdapter()
		 * @see com.codecatalyst.promise.adapter.AsyncTokenAdapter
		 */
		public static function when( value:* ):Promise
		{
			for each ( var adapt:Function in adapters )
			{
				const promise:Promise = adapt( value ) as Promise;
				if ( promise )
				{
					return promise;
				}
			}
			
			const deferred:Deferred = new Deferred();
			deferred.resolve( value );
			return deferred.promise;
		}
		
		/**
		 * Logs a message with the specified category, log level and optional 
		 * parameters via all registered custom logger functions.
		 * 
		 * @see #registerLogger()
		 * @see #unregisterLogger()
		 * @see com.codecatalyst.promise.logger.FlexLogger
		 * @see com.codecatalyst.promise.logger.TraceLogger
		 */
		public static function log( category:String, level:int, message:String, ...parameters ):void
		{
			var loggerParameters:Array = [ category, level, message ].concat( parameters );
			for each ( var logger:Function in loggers )
			{
				logger.apply( logger, loggerParameters );
			}
		}

		/**
		 * Registers a custom adapter function capable of adapting values
		 * passed to <code>Promise.when()</code> into Promises.
		 * 
		 * A custom adapter function is called with a candidate value and
		 * should return either a Promise that adapts that value or null if the
		 * adapter cannot adapt that value.
		 * 
		 * @example A custom adapter should have the following function signature:
		 * <listing version="3.0">
		 * function function adapt( value:* ):Promise {
		 *    // ...
		 * }
		 * </listing>
		 * 
		 * @see #unregisterAdapter()
		 */
		public static function registerAdapter( adapter:Function ):void
		{
			if ( adapters.indexOf( adapter ) == -1 )
			{
				adapters.push( adapter );
			}
		}

		/**
		 * Unregisters a custom adapter function.
		 * 
		 * @see #registerAdapter()
		 */
		public static function unregisterAdapter( adapter:Function ):void
		{
			const index:int = adapters.indexOf( adapter );
			if ( index > -1 )
			{
				adapters.splice( index, 1 );
			}
		}
		
		/**
		 * Registers a custom logger function capable of logging messages
		 * with a specified category, log level, and optional parameters.
		 * 
		 * @example A custom logger should have the following function signature:
		 * <listing version="3.0">
		 * function log( category:String, level:int, message:String, ...parameters ):void {
		 *    // ...
		 * }
		 * </listing>
		 * 
		 * @see #unregisterLogger()
		 */
		public static function registerLogger( logger:Function ):void
		{
			if ( loggers.indexOf( logger ) == -1 )
			{
				loggers.push( logger );
			}
		}
		
		/**
		 * Unregisters a custom logger function.
		 * 
		 * @see #registerLogger()
		 */
		public static function unregisterLogger( logger:Function ):void
		{
			const index:int = loggers.indexOf( logger );
			if ( index > -1 )
			{
				loggers.splice( index, 1 );
			}
		}
		
		// ========================================
		// Private static properties
		// ========================================
		
		/**
		 * Array of registered adapter functions.
		 */
		private static const adapters:Array = [];
		
		/**
		 * Array of registered logger functions.
		 */
		private static const loggers:Array = [];
		
		// ========================================
		// Private properties
		// ========================================
		
		/**
		 * Internal Resolver for this Promise.
		 */
		private var resolver:Resolver;
		
		// ========================================
		// Constructor
		// ========================================
		
		public function Promise( resolver:Resolver )
		{
			this.resolver = resolver;	
		}
		
		// ========================================
		// Public methods
		// ========================================
		
		/**
		 * Attaches <code>onFulfilled</code> and <code>onRejected</code>
		 * callbacks that will be notified when the future value becomes 
		 * available.
		 * 
		 * Those callbacks can subsequently transform the value that was 
		 * fulfilled or the error that was rejected. Each call to then() 
		 * returns a new Promise of that transformed value; i.e., a Promise 
		 * that is fulfilled with the callback return value or rejected with 
		 * any error thrown by the callback.
		 * 
		 * @param onFulfilled Callback to execute to transform a fulfillment value.
		 * @param onRejected Callback to execute to transform a rejection reason.
		 * 
		 * @return Promise that is fulfilled with the callback return value or rejected with any error thrown by the callback.
		 */
		public function then( onFulfilled:Function = null, onRejected:Function = null ):Promise
		{
			return resolver.then( onFulfilled, onRejected );
		}
		
		/**
		 * Attaches an <code>onRejected</code> callback that will be 
		 * notified if this Promise is rejected.
		 * 
		 * The callback can subsequently transform the reason that was 
		 * rejected. Each call to otherwise() returns a new Promise of that 
		 * transformed value; i.e., a Promise that is resolved with the 
		 * original resolved value, or resolved with the callback return value
		 * or rejected with any error thrown by the callback.
		 *
		 * @param onRejected Callback to execute to transform a rejection reason.
		 * 
		 * @return Promise of the transformed future value.
		 */
		public function otherwise( onRejected:Function ):Promise
		{
			return resolver.then( null, onRejected );
		}

		/**
		 * Attaches an <code>onCompleted</code> callback that will be 
		 * notified when the future value becomes available.
		 * 
		 * Similar to "finally" in "try..catch..finally".
		 * 
		 * NOTE: The specified callback does not affect the resulting Promise's
		 * outcome; any return value is ignored and any Error is rethrown.
		 * 
		 * @param onCompleted Callback to execute when the Promise is resolved or rejected.
		 * 
		 * @return A new "pass-through" Promise that is resolved with the original value or rejected with the original reason.
		 */
		public function always( onCompleted:Function ):Promise
		{
			function onFulfilled( value:* ):*
			{
				try
				{
					onCompleted();
				}
				catch ( error:Error )
				{
					scheduleRethrowError( error );
				}
				return value;
			}
			
			function onRejected( reason:* ):*
			{
				try
				{
					onCompleted();
				}
				catch ( error:Error )
				{
					scheduleRethrowError( error );
				}
				throw reason;
			}			
			
			return resolver.then( onFulfilled, onRejected );
		}
		
		/**
		 * Terminates a Promise chain, ensuring that unhandled rejections will 
		 * be rethrown as Errors.
		 * 
		 * One of the pitfalls of interacting with Promise-based APIs is the 
		 * tendency for important errors to be silently swallowed unless an 
		 * explicit rejection handler is specified.
		 * 
		 * @example For example:
		 * <listing version="3.0">
		 * var promise:Promise = doWork().then( function () {
		 *     // logic in your callback throws an error and it is interpreted as a rejection.
		 *     throw new Error('Boom!');
		 * });
		 * // The Error was not handled by the Promise chain and is silently swallowed.
		 * </listing>
		 * 
		 * @example This problem can be addressed by terminating the Promise chain with the done() method:
		 * <listing version="3.0">
		 * var promise:Promise = doWork().then( function () {
		 *     // logic in your callback throws an error and it is interpreted as a rejection.
		 *     throw new Error('Boom!');
		 * }).done();
		 * // The Error was not handled by the Promise chain and is rethrown by done() on the next tick.
		 * </listing>
		 * 
		 * The done() method ensures that any unhandled rejections are rethrown 
		 * as Errors.
		 */
		public function done():void
		{
			resolver.then( null, scheduleRethrowError );
		}
		
		/**
		 * Cancels this Promise if it is still pending, triggering a rejection 
		 * with a CancellationError that will propagate to any Promises 
		 * originating from this Promise.
		 * 
		 * NOTE: Cancellation only propagates to Promises that branch from the 
		 * target Promise. It does not traverse back up to parent branches, as 
		 * this would reject nodes from which other Promises may have branched, 
		 * causing unintended side-effects.
		 * 
		 * @param reason Cancellation reason.
		 */
		public function cancel( reason:* ):void
		{
			resolver.reject( new CancellationError( reason ) );
		}
		
		
		/**
		 * Logs the resolution or rejection of this Promise with the specified
		 * category and optional identifier. Messages are logged via all 
		 * registered custom logger functions.
		 * 
		 * @param category Logging category, typically a class name or package.
		 * @param identifier An optional identifier to incorporate into the resulting log entry.
		 * 
		 * @return A new "pass-through" Promise that is resolved with the original value or rejected with the original reason.
		 * 
		 * @see #registerLogger()
		 * @see #unregisterLogger()
		 * @see com.codecatalyst.promise.logger.FlexLogger
		 * @see com.codecatalyst.promise.logger.TraceLogger
		 */
		public function log( category:String, identifier:String = null ):Promise
		{
			function onFulfilled( value:* ):*
			{
				try
				{
					Promise.log( category, LogLevel.DEBUG, ( identifier || "Promise" ) + " resolved with value: " + value );
				}
				catch ( error:Error )
				{
					scheduleRethrowError( error );
				}
				return value;
			}
			
			function onRejected( reason:* ):*
			{
				try
				{
					Promise.log( category, LogLevel.ERROR, ( identifier || "Promise" ) + " rejected with reason: " + reason );
				}
				catch ( error:Error )
				{
					scheduleRethrowError( error );
				}
				throw reason;
			}
			
			return resolver.then( onFulfilled, onRejected );
		}
		
		// ========================================
		// Private methods
		// ========================================
		
		/**
		 * Schedules an Error to be rethrown in the future.
		 * 
		 * @param error Error to be thrown.
		 */
		private function scheduleRethrowError( error:* ):void
		{
			nextTick( rethrowError, [ error ] );
		}
		
		/**
		 * Rethrows the specified Error, prepending the original stack trace.
		 *  
		 * @param error Error to be thrown.
		 */
		private function rethrowError( error:* ):void
		{
			throw error.getStackTrace() + "\nRethrown from:";
		}
	}
}