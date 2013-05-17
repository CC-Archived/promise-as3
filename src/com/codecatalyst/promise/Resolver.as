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
	import com.codecatalyst.util.nextTick;

	/**
	 * Resolvers are used internally by Deferreds and Promises to capture and 
	 * notify callbacks, process callback return values and propagate resolution
	 * or rejection to chained Resolvers.
	 * 
	 * Developers never directly interact with a Resolver.
	 * 
	 * A Resolver captures a pair of optional onResolved and onRejected 
	 * callbacks and has an associated Promise. That Promise delegates its
	 * then() calls to the Resolver's then() method, which creates a new 
	 * Resolver and schedules its delayed addition as a chained Resolver.
	 * 
	 * Each Deferred has an associated Resolver. A Deferred delegates resolve()
	 * and reject() calls to that Resolver's resolve() and reject() methods. 
	 * The Resolver processes the resolution value and rejection reason, and 
	 * propagates the processed resolution value or rejection reason to any
	 * chained Resolvers it may have created in response to then() calls. Once 
	 * a chained Resolver has been notified, it is cleared out of the set of 
	 * chained Resolvers and will not be notified again.
	 */
	internal class Resolver
	{
		// ========================================
		// Public properties
		// ========================================
		
		/**
		 * Promise of the future value of this Resolver.
		 */
		public function get promise():Promise
		{
			return _promise;
		}
		
		// ========================================
		// Protected properties
		// ========================================
		
		/**
		 * Backing variable for <code>promise</code>.
		 */
		protected var _promise:Promise;
		
		/**
		 * Callback to execute when this Resolver's future value is resolved.
		 */
		protected var onResolved:Function;
		
		/**
		 * Callback to execute when this Resolver's future value is rejected.
		 */
		protected var onRejected:Function;
		
		[ArrayElementType("com.codecatalyst.promise.Resolver")]
		/**
		 * Pending chained resolvers.
		 */
		protected var pending:Array = [];
		
		/**
		 * Indicates whether this Resolver has been processed.
		 */
		protected var processed:Boolean;
		
		/**
		 * Indicates whether this Resolver has been completed.
		 */
		protected var completed:Boolean;
		
		/**
		 * The completion action (i.e. 'resolve' or 'reject').
		 */
		protected var completionAction:String;
		
		/**
		 * The completion value (i.e. resolution value or rejection error).
		 */
		protected var completionValue:*;
		
		// ========================================
		// Constructor
		// ========================================
		
		public function Resolver( onResolved:Function = null, onRejected:Function = null )
		{
			this.onResolved = onResolved;
			this.onRejected = onRejected || explode;
			this._promise = new Promise(this);
		}
		
		// ========================================
		// Public methods
		// ========================================
		
		/**
		 * Resolve this Resolver with the specified value.
		 * 
		 * Once a Resolver has been resolved, it is considered to be complete 
		 * and subsequent calls to resolve() or reject() are ignored.
		 */
		public function resolve( result:* ):void
		{
			if ( !processed )
				process( onResolved, result );
		}
		
		
		/**
		 * Reject this Resolver with the specified value.
		 * 
		 * Once a Resolver has been rejected, it is considered to be complete 
		 * and subsequent calls to resolve() or reject() are ignored.
		 */
		public function reject( error:* ):void
		{
			if ( !processed )
				process( onRejected, error );
		}
		
		/**
		 * Used to specify <code>onResolved</code> and <code>onRejected</code>
		 * callbacks that will be notified when the future value becomes 
		 * available.
		 * 
		 * Those callbacks can subsequently transform the value that was 
		 * resolved or the error that was rejected. Each call to then() 
		 * returns a new Promise of that transformed value; i.e., a Promise 
		 * that is resolved with the callback return value or rejected with 
		 * any error thrown by the callback.
		 */
		public function then( onResolved:Function = null, onRejected:Function = null ):Promise
		{
			if ( onResolved != null || onRejected != null )
			{
				const pendingResolver:Resolver = new Resolver( onResolved, onRejected );
				nextTick( schedule, [pendingResolver] );
				return pendingResolver.promise;
			}
			
			return promise;
		}
		
		// ========================================
		// Protected methods
		// ========================================
		
		/**
		 * Propagate the completion value to any pending Resolvers.
		 */
		protected function propagate():void
		{
			for each ( var resolver:Resolver in pending.splice(0) )
			{
				resolver[ completionAction ]( completionValue );
			}
		}
		
		/**
		 * Schedule a Resolver as a pending Resolver, to be notified in a
		 * future event loop tick when the future value becomes available.
		 */
		protected function schedule( resolver:Resolver ):void
		{
			pending.push( resolver );
			
			if ( completed )
				propagate();
		}
		
		/**
		 * Completes this Resolver.
		 */
		protected function complete( action:String, value:* ):void
		{
			onResolved = null;
			onRejected = null;
			completionAction = action;
			completionValue = value;
			completed = true;
			
			propagate();
		}
		
		/**
		 * Completes this Resolver a resolved result.
		 */
		protected function completeResolved( result:* ):void
		{
			complete( 'resolve', result );
		}
		
		/**
		 * Completes this Resolver with a rejection error.
		 */
		protected function completeRejected( error:* ):void
		{
			complete( 'reject', error );
		}
		
		/**
		 * Processes the resolved value or rejection error using the 
		 * specified callback.
		 */
		protected function process( callback:Function, value:* ):void
		{
			processed = true;
			
			try
			{
				if ( callback != null )
				{
					// Allow handlers without arguments
					const result:* = callback.length == 0
							? callback()
							: callback(value);

					// Do not overwrite the value for undefined returns (void)
					if (result !== undefined)
						value = result;
				}

				// Softly check for a returned Promise
				if ( value != null && "then" in value && value.then is Function )
				{
					value.then( completeResolved, completeRejected );
				}
				else
				{
					completeResolved( value );
				}
			}
			catch ( error:* )
			{
				completeRejected( error );
			}
		}

		/**
		 * Default rejection handler, used when none is specified in order
		 * to propagate errors to chained Resolvers.
		 *
		 * @param error The uncaught error
		 */
		private function explode(error:*):void
		{
			throw error;
		}
	}
}