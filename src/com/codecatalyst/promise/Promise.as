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
	import com.codecatalyst.util.optionally;
	import com.codecatalyst.util.spread;
	
	import flash.events.TimerEvent;
	import flash.utils.Timer;

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
		 * @param value An immediate value, a Promise, a foreign Promise or adaptable value.
		 * @return Promise of the specified value.
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
		 * Determines whether the specified value is a thenable, i.e. an Object
		 * or Function that exposes a then() method and may therefore be an 
		 * third-party untrusted Promise, based on the Promises/A 
		 * specification feature test.
		 * 
		 * @param value A potential thenable.
		 * @return Boolean indicating whether the specified value was a thenable.
		 */
		public static function isThenable( value:* ):Boolean
		{
			return ( value != null && ( value is Object || value is Function ) && "then" in value && value.then is Function );
		}
		
		/**
		 * Returns a new Promise that will only fulfill once all the specified
		 * Promises and/or values have been fulfilled, and will reject if any
		 * of the specified Promises is rejected. The resolution value will be 
		 * an Array containing the fulfilled value of each of the Promises or 
		 * values.
		 * 
		 * @param promisesOrValues An Array of values or Promises, or a Promise of an Array of values or Promises.
		 * @returns Promise of an Array of the fulfilled values.
		 */
		public static function all( promisesOrValues:* ):Promise
		{
			if ( ! ( promisesOrValues is Array || Promise.isThenable( promisesOrValues ) ) )
			{
				throw new Error( "Invalid parameter: expected an Array or Promise of an Array." );
			}
			
			function process( promisesOrValues:Array ):Promise
			{
				var remainingToResolve:uint = promisesOrValues.length;
				var results:Array = new Array( promisesOrValues.length );
				
				var deferred:Deferred = new Deferred();
				
				if ( remainingToResolve > 0 )
				{
					function resolve( item:*, index:uint ):Promise
					{
						function fulfill( value:* ):*
						{
							results[ index ] = value;
							if ( --remainingToResolve == 0 )
							{
								deferred.resolve( results )
							}
							return value;
						}
						
						return Promise.when( item ).then( fulfill, deferred.reject );
					}
					
					for ( var index:uint = 0; index < promisesOrValues.length; index++ )
					{
						if ( index in promisesOrValues )
						{
							resolve( promisesOrValues[ index ], index );
						}
						else
						{
							remainingToResolve--;
						}
					}
				}
				else
				{
					deferred.resolve( results );
				}
				
				return deferred.promise;
			}
			
			return Promise.when( promisesOrValues ).then( process );
		}
		
		/**
		 * Initiates a competitive race, returning a new Promise that will 
		 * fulfill when any one of the specified Promises or values is 
		 * fulfilled, or will only reject once all of the Promises have
		 * been rejected.
		 * 
		 * @param promisesOrValues An Array of values or Promises, or a Promise of an Array of values or Promises.
		 * @return Promise of the first resolved value.
		 */
		public static function any( promisesOrValues:* ):Promise
		{
			if ( ! ( promisesOrValues is Array || Promise.isThenable( promisesOrValues ) ) )
			{
				throw new Error( "Invalid parameter: expected an Array or Promise of an Array." )
			}
			
			function extract( array:Array ):*
			{
				return array[ 0 ];
			}
			
			function transform( reason:* ):void
			{
				if ( reason is Error && reason.message == "Too few Promises were resolved." )
				{
					throw new Error( "No Promises were resolved." );
				}
				throw reason;
			}

			return Promise.some( promisesOrValues, 1 ).then( extract, transform );
		}
		
		/**
		 * Initiates a competitive race, returning a new Promise that will 
		 * fulfill when the expected number of Promises and/or values have
		 * been fulfilled, or will reject when it becomes impossible for the
		 * expected number to fulfill.
		 * 
		 * @param promisesOrValues An Array of values or Promises, or a Promise of an Array of values or Promises.
		 * @param howMany The expected number of fulfilled values.
		 * @return Promise of the expected number of fulfilled values.
		 */
		public static function some( promisesOrValues:*, howMany:uint ):Promise
		{
			if ( ! ( promisesOrValues is Array || Promise.isThenable( promisesOrValues ) ) )
			{
				throw new Error( "Invalid parameter: expected an Array or Promise of an Array." )
			}
			
			function process( promisesOrValues:Array ):Promise
			{
				var values:Array = [];
				var remainingToResolve:uint = howMany;
				var remainingToReject:uint = ( promisesOrValues.length - remainingToResolve ) + 1;
				
				var deferred:Deferred = new Deferred();
				
				if ( promisesOrValues.length < howMany )
				{
					deferred.reject( new Error( "Too few Promises were resolved." ) );
				}
				else
				{
					function onResolve( value:* ):*
					{
						if ( remainingToResolve > 0 ) {
							values.push( value );
						}
						remainingToResolve--;
						if ( remainingToResolve == 0 )
						{
							deferred.resolve( values );
						}
						return value;
					}
					
					function onReject( reason:* ):*
					{
						remainingToReject--;
						if ( remainingToReject == 0 )
						{
							deferred.reject( new Error( "Too few Promises were resolved." ) )
						}
						throw reason;
					}
					
					for ( var index:uint = 0; index < promisesOrValues.length; index++ )
					{
						if ( index in promisesOrValues )
						{
							Promise.when( promisesOrValues[ index ] ).then( onResolve, onReject );
						}
					}
				}
				
				return deferred.promise;
			}
			
			return Promise.when( promisesOrValues ).then( process );
		}
		
		/**
		 * Returns a new Promise that will automatically resolve with the 
		 * specified Promise or value after the specified delay 
		 * (in milliseconds).
		 *
		 * @param promiseOrValue A Promise or value.
		 * @param milliseconds Delay duration (in milliseconds).
		 * @return Promise of the specified Promise or value that will resolve after the specified delay.
		 */
		public static function delay( promiseOrValue:*, milliseconds:Number ):Promise
		{
			var deferred:Deferred = new Deferred();
			
			function timerCompleteHandler():void
			{
				timer.removeEventListener( TimerEvent.TIMER_COMPLETE, timerCompleteHandler );
				
				deferred.resolve( promiseOrValue );
			}
			
			var timer:Timer = new Timer( Math.max( milliseconds, 0 ), 1 );
			timer.addEventListener( TimerEvent.TIMER_COMPLETE, timerCompleteHandler );
			
			timer.start(); 
			
			return deferred.promise;
		}
		
		/**
		 * Returns a new Promise that will automatically reject with a 
		 * TimeoutError after the specified timeout (in milliseconds) if 
		 * the specified promise has not fulfilled or rejected.
		 * 
		 * @param promiseOrValue A Promise or value.
		 * @param milliseconds Timeout duration (in milliseconds).
		 * @return Promise of the specified Promise or value that enforces the specified timeout.
		 */
		public static function timeout( promiseOrValue:*, milliseconds:Number ):Promise
		{
			var deferred:Deferred = new Deferred();
			
			function timerCompleteHandler():void
			{
				timer.removeEventListener( TimerEvent.TIMER_COMPLETE, timerCompleteHandler );
				
				deferred.reject( new TimeoutError() );
			}
			
			var timer:Timer = new Timer( Math.max( milliseconds, 0 ), 1 );
			timer.addEventListener( TimerEvent.TIMER_COMPLETE, timerCompleteHandler );
			timer.start();
			
			Promise.when( promiseOrValue ).then( deferred.resolve, deferred.reject );
			
			return deferred.promise;
		}
		
		/**
		 * Traditional map function that allows input to contain Promises and/or values.
		 * 
		 * @param promisesOrValues An Array of values or Promises, or a Promise of an Array of values or Promises.
		 * @param mapFunction Function to call to transform each resolved value in the Array.
		 * @return Promise of an Array of mapped values.
		 */
		public static function map( promisesOrValues:*, mapFunction:Function ):Promise
		{
			if ( ! ( promisesOrValues is Array || Promise.isThenable( promisesOrValues ) ) )
			{
				throw new Error( "Invalid parameter: expected an Array or Promise of an Array." )
			}
			if ( ! ( mapFunction is Function ) )
			{
				throw new Error( "Invalid parameter: expected a function." )
			}
			
			function process( promisesOrValues:Array ):Promise
			{
				var remainingToResolve:uint = promisesOrValues.length;
				var results:Array = new Array( promisesOrValues.length );
				
				var deferred:Deferred = new Deferred();
				
				if ( remainingToResolve > 0 )
				{
					function resolve( item:*, index:uint ):Promise
					{
						function transform( value:* ):*
						{
							return optionally( mapFunction, [ value, index, results ] );
						}
						
						function fulfill( value:* ):void
						{
							results[ index ] = value;
							if ( --remainingToResolve == 0 )
							{
								deferred.resolve( results )
							}
						}
						
						return Promise.when( item ).then( transform ).then( fulfill, deferred.reject );
					}
					
					for ( var index:uint = 0; index < promisesOrValues.length; index++ )
					{
						if ( index in promisesOrValues )
						{
							resolve( promisesOrValues[ index ], index );
						}
						else
						{
							remainingToResolve--;
						}
					}
				}
				else
				{
					deferred.resolve( results );
				}
				
				return deferred.promise;
			}
			
			return Promise.when( promisesOrValues ).then( process );
		}
		
		/**
		 * Traditional reduce function that allows input to contain Promises and/or values.
		 * 
		 * @param promisesOrValues An Array of values or Promises, or a Promise of an Array of values or Promises.
		 * @param reduceFn Function to call to transform each successive item in the Array into the final reduced value.
		 * @param initialValue Initial Promise or value.
		 * @return Promise of the reduced value.
		 */
		public static function reduce( promisesOrValues:*, reduceFunction:Function, ...rest ):Promise
		{
			if ( ! ( promisesOrValues is Array || Promise.isThenable( promisesOrValues ) ) )
			{
				throw new Error( "Invalid parameter: expected an Array or Promise of an Array." );
			}
			if ( ! ( reduceFunction is Function ) )
			{
				throw new Error( "Invalid parameter: expected a function." );
			}
			
			function reduceArray( array:Array, reduceFunction:Function, ...rest ):*
			{
				var index:uint = 0;
				var length:uint = array.length;
				var reduced:* = null;
				
				// If no initialValue, use first item of Array and adjust index to start at second item
				if ( rest.length == 0 ) {
					for ( index = 0; index < length; index++ )
					{
						if ( index in array )
						{
							reduced = array[ index ];
							index++;
							break;
						}
					}
				}
				else
				{
					reduced = rest[ 0 ];
				}
				
				while ( index < length )
				{
					if ( index in array )
					{
						reduced = reduceFunction( reduced, array[ index ], index, array );
						index++
					}
				}
				
				return reduced;
			}
			
			function process( promisesOrValues:Array ):Promise
			{
				// Wrap the reduce function with one that handles promises and then delegates to it.
				function reduceFnWrapper( previousValueOrPromise:*, currentValueOrPromise:*, currentIndex:uint, array:Array ):Promise
				{
					function execute( previousValue:*, currentValue:* ):*
					{
						return optionally( reduceFunction, [ previousValue, currentValue, currentIndex, array ] );
					}
					
					return Promise.all( [ previousValueOrPromise, currentValueOrPromise ] ).then( spread( execute ) );
				}
				
				if ( rest.length > 0 )
				{
					var initialValue:* = rest[ 0 ];
					return reduceArray( promisesOrValues, reduceFnWrapper, initialValue );
				}
				else
				{
					return reduceArray( promisesOrValues, reduceFnWrapper );
				}
			}
			
			return Promise.when( promisesOrValues ).then( process );
		}
		
		/**
		 * Logs a message with the specified category, log level and optional 
		 * parameters via all registered custom logger functions.
		 * 
		 * @param category Category
		 * @param level Log level
		 * @param message Message
		 * @param parameters Optional message parameters
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
		 * @param adapter Adapter function.
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
		 * @param adapter Previously registered adapter function.
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
		 * @param adapter Custom logger function.
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
		 * @param adapter Previously registered custom logger function.
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
		// Private static methods
		// ========================================
		
		/**
		 * Schedules an Error to be rethrown in the future.
		 * 
		 * @param error Error to be thrown.
		 */
		private static function scheduleRethrowError( error:* ):void
		{
			nextTick( rethrowError, [ error ] );
		}
		
		/**
		 * Rethrows the specified Error, prepending the original stack trace.
		 *  
		 * @param error Error to be thrown.
		 */
		private static function rethrowError( error:* ):void
		{
			if ( error is Error )
			{
				throw error.getStackTrace() + "\nRethrown from:";
			}
			else
			{
				throw error;
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
		 * Attaches onFulfilled and onRejected callbacks that will be
		 * notified when the future value becomes available.
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
		 * Attaches an onRejected callback that will be notified if this
		 * Promise is rejected.
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
		 * Attaches an onCompleted callback that will be notified when this
		 * Promise is completed.
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
		 * promise
		 *     .then( function () {
		 *         // logic in your callback throws an error and it is interpreted as a rejection.
		 *         throw new Error("Boom!");
		 *     });
		 * // The Error was not handled by the Promise chain and is silently swallowed.
		 * </listing>
		 * 
		 * @example This problem can be addressed by terminating the Promise chain with the done() method:
		 * <listing version="3.0">
		 * promise
		 *     .then( function () {
		 *         // logic in your callback throws an error and it is interpreted as a rejection.
		 *         throw new Error("Boom!");
		 *     })
		 *     .done();
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
	}
}