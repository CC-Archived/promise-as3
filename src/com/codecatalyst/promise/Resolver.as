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
	 * Resolvers are used internally by Deferreds to create, resolve and reject 
	 * Promises, and to propagate fulfillment and rejection.
	 * 
	 * Developers never directly interact with a Resolver.
	 * 
	 * Each Deferred has an associated Resolver, and each Resolver has an 
	 * associated Promise. A Deferred delegates resolve() and reject() calls to 
	 * its Resolver's resolve() and reject() methods. A Promise delegates 
	 * then() calls to its Resolver's then() method. In this way, access to 
	 * Resolver operations are divided between producer (Deferred) and consumer 
	 * (Promise) roles.
	 * 
	 * When a Resolver's resolve() method is called, it fulfills with the 
	 * optionally specified value. If resolve() is called with a then-able 
	 * (i.e.a Function or Object with a then() function, such as another 
	 * Promise) it assimilates the then-able's result; the Resolver provides 
	 * its own resolve() and reject() methods as the onFulfilled or onRejected 
	 * arguments in a call to that then-able's then() function. If an error is 
	 * thrown while calling the then-able's then() function (prior to any call 
	 * back to the specified resolve() or reject() methods), the Resolver 
	 * rejects with that error. If a Resolver's resolve() method is called with 
	 * its own Promise, it rejects with a TypeError.
	 * 
	 * When a Resolver's reject() method is called, it rejects with the 
	 * optionally specified reason.
	 * 
	 * Each time a Resolver's then() method is called, it captures a pair of 
	 * optional onFulfilled and onRejected callbacks and returns a Promise of 
	 * the Resolver's future value as transformed by those callbacks.
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
		// Private properties
		// ========================================
		
		/**
		 * Backing variable for <code>promise</code>.
		 */
		private var _promise:Promise = null;
		
		[ArrayElementType("com.codecatalyst.promise.Consequence")]
		/**
		 * Pending Consequences chained to this Resolver.
		 */
		private var consequences:Array = [];
		
		/**
		 * Indicates whether this Resolver has been completed.
		 */
		private var completed:Boolean = false;
		
		/**
		 * The completion action (i.e. CompletionAction.FULFILL or CompletionAction.REJECT).
		 */
		private var completionAction:String = null;
		
		/**
		 * The completion value (i.e. resolution value or rejection error).
		 */
		private var completionValue:* = undefined;
		
		// ========================================
		// Constructor
		// ========================================
		
		public function Resolver()
		{
			this._promise = new Promise( this );
			this.consequences = [];
		}
		
		// ========================================
		// Public methods
		// ========================================
		
		/**
		 * Used to specify <code>onFulfilled</code> and <code>onRejected</code>
		 * callbacks that will be notified when the future value becomes 
		 * available.
		 * 
		 * Those callbacks can subsequently transform the value that was 
		 * fulfilled or the error that was rejected. Each call to then() 
		 * returns a new Promise of that transformed value; i.e., a Promise 
		 * that is fulfilled with the callback return value or rejected with 
		 * any error thrown by the callback.
		 * 
		 * @param onFulfilled (Optional) callback to execute to transform a fulfillment value.
		 * @param onRejected (Optional) callback to execute to transform a rejection reason.
		 * 
		 * @return Promise that is fulfilled with the callback return value or rejected with any error thrown by the callback.
		 */
		public function then( onFulfilled:Function = null, onRejected:Function = null ):Promise
		{
			var consequence:Consequence = new Consequence( onFulfilled, onRejected );
			if ( completed )
			{
				consequence.trigger( completionAction, completionValue );
			}
			else
			{
				consequences.push( consequence );
			}
			
			return consequence.promise;
		}
		
		/**
		 * Resolve this Resolver with the (optional) specified value.
		 * 
		 * If called with a then-able (i.e.a Function or Object with a then() 
		 * function, such as another Promise) it assimilates the then-able's 
		 * result; the Resolver provides its own resolve() and reject() methods
		 * as the onFulfilled or onRejected arguments in a call to that 
		 * then-able's then() function.  If an error is  thrown while calling 
		 * the then-able's then() function (prior to any call back to the 
		 * specified resolve() or reject() methods), the Resolver rejects with 
		 * that error. If a Resolver's resolve() method is called with its own 
		 * Promise, it rejects with a TypeError.
		 * 
		 * Once a Resolver has been fulfilled or rejected, it is considered to be complete 
		 * and subsequent calls to resolve() or reject() are ignored.
		 * 
		 * @param value Value to resolve as either a fulfillment value or rejection reason.
		 */
		public function resolve( value:* ):void
		{
			if ( completed )
			{
				return;
			}
			
			try
			{
				if ( value == Promise )
				{
					throw new TypeError( "A Promise cannot be resolved with itself." );
				}
				var thenFn:Function; // NOTE: We must only call value.then once!
				if ( value != null && ( value is Object || value is Function ) && "then" in value && ( thenFn = value.then ) is Function )
				{
					var isHandled:Boolean = false;
					var self:Resolver = this;
					try
					{
						thenFn.call( 
							value, 
							function ( value:* ):void
							{
								if ( !isHandled )
								{
									isHandled = true;
									self.resolve( value );
								}
							},
							function ( reason:* ):void
							{
								if ( !isHandled )
								{
									isHandled = true;
									self.reject( reason );
								}
							}
						);
					}
					catch ( error:* )
					{
						if ( !isHandled )
						{
							reject( error );
						}
					}
				}
				else
				{
					complete( CompletionAction.FULFILL, value );
				}
			}
			catch ( error:* )
			{
				reject( error );
			}
		}
		
		/**
		 * Reject this Resolver with the specified reason.
		 * 
		 * Once a Resolver has been rejected, it is considered to be complete 
		 * and subsequent calls to resolve() or reject() are ignored.
		 * 
		 * @param reason Rejection reason.
		 */
		public function reject( reason:* ):void
		{
			if ( completed )
			{
				return;
			}
			
			complete( CompletionAction.REJECT, reason );
		}
		
		// ========================================
		// Private methods
		// ========================================
		
		/**
		 * Complete this Resolver with the specified action and value.
		 * 
		 * @param action Completion action (i.e. CompletionAction.FULFILL or CompletionAction.REJECT).
		 * @param value Fulfillment value or rejection reason.
		 */
		private function complete( action:String, value:* ):void
		{
			completionAction = action;
			completionValue = value;
			completed = true;
			
			for each ( var consequence:Consequence in consequences )
			{
				consequence.trigger( completionAction, completionValue );
			}
			consequences = [];
		}
	}
}