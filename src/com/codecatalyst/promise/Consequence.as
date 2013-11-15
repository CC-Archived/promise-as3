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
	 * Consequences are used internally by a Resolver to capture and notify 
	 * callbacks, and propagate their transformed results as fulfillment or 
	 * rejection.
	 * 
	 * Developers never directly interact with a Consequence.
	 * 
	 * A Consequence forms a chain between two Resolvers, where the result of 
	 * the first Resolver is transformed by the corresponding callback before 
	 * being applied to the second Resolver.
	 * 
	 * Each time a Resolver's then() method is called, it creates a new 
	 * Consequence that will be triggered once its originating Resolver has 
	 * been fulfilled or rejected. A Consequence captures a pair of optional 
	 * onFulfilled and onRejected callbacks.
	 * 
	 * Each Consequence has its own Resolver (which in turn has a Promise) 
	 * that is resolved or rejected when the Consequence is triggered. When a 
	 * Consequence is triggered by its originating Resolver, it calls the 
	 * corresponding callback and propagates the transformed result to its own 
	 * Resolver; resolved with the callback return value or rejected with any 
	 * error thrown by the callback.
	 */
	internal class Consequence
	{
		// ========================================
		// Public properties
		// ========================================
		
		/**
		 * Promise of the future value of this Consequence.
		 */
		public function get promise():Promise
		{
			return resolver.promise;
		}
		
		// ========================================
		// Private properties
		// ========================================
		
		/**
		 * Internal Resolver for this Consequence.
		 */
		private var resolver:Resolver = null;
		
		/**
		 * Callback to execute when this Consequence is triggered with a fulfillment value.
		 */
		private var onFulfilled:Function = null;
		
		/**
		 * Callback to execute when this Consequence is triggered with a rejection reason.
		 */
		private var onRejected:Function = null;
				
		// ========================================
		// Constructor
		// ========================================
		
		/**
		 * Constructor.
		 * 
		 * @param onFulfilled Callback to execute to transform a fulfillment value.
		 * @param onRejected Callback to execute to transform a rejection reason.
		 */
		public function Consequence( onFulfilled:Function, onRejected:Function )
		{
			this.onFulfilled = onFulfilled;
			this.onRejected = onRejected;
			
			this.resolver = new Resolver();
		}
		
		// ========================================
		// Public methods
		// ========================================
		
		/**
		 * Trigger this Consequence with the specified action and value.
		 * 
		 * @param action Completion action (i.e. CompletionAction.FULFILL or CompletionAction.REJECT).
		 * @param value Fulfillment value or rejection reason.
		 */
		public function trigger( action:String, value:* ):void
		{
			switch ( action )
			{
				case CompletionAction.FULFILL:
					propagate( value, onFulfilled, resolver.resolve );
					break;
				
				case CompletionAction.REJECT:
					propagate( value, onRejected, resolver.reject );
					break;
			}
		}
		
		// ========================================
		// Private methods
		// ========================================
		
		/**
		 * Propagate the specified value using either the optional callback or
		 * a Resolver method.
		 * 
		 * @param value Value to transform and/or propagate.
		 * @param callback (Optional) callback to use to transform the value. 
		 * @param resolverMethod Resolver method to call to propagate the value, if no callback was specified.
		 */
		private function propagate( value:*, callback:Function, resolverMethod:Function ):void
		{
			if ( callback is Function )
			{
				nextTick( transform, [ value, callback ] );
			}
			else
			{
				resolverMethod.call( resolver, value );
			}
		}
		
		/**
		 * Transform the specified value using the specified callback and 
		 * propagate the transformed result.
		 * 
		 * @param value Value to transform.
		 * @param callback Callback to execute to transform the value.
		 */
		private function transform( value:*, callback:Function ):void
		{
			try
			{
				resolver.resolve( callback.length == 0 ? callback() : callback( value ) );
			}
			catch ( error:* ) 
			{
				resolver.reject( error );
			}
		}
	}
}