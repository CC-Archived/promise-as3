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
	/**
	 * A Deferred is typically used within the body of a function that performs
	 * an asynchronous operation. When that operation succeeds, the Deferred 
	 * should be resolved; if that operation fails, the Deferred should be rejected.
	 * 
	 * Deferreds are the mechanism used to create new Promises. A Deferred has a 
	 * single associated Promise that can be safely returned to external consumers 
	 * to ensure they do not interfere with the resolution or rejection of the 
	 * deferred operation.
	 */
	public class Deferred
	{
		// ========================================
		// Public properties
		// ========================================
		
		/**
		 * Promise of the future value of this Deferred.
		 */
		public function get promise():Promise
		{
			return resolver.promise;
		}
		
		// ========================================
		// Protected properties
		// ========================================
		
		/**
		 * Internal Resolver for this Deferred.
		 */
		protected var resolver:Resolver;
		
		// ========================================
		// Constructor
		// ========================================

      /**
       * Constructor supports immediate callback
       *
       * @param callback
       * @param scope
       */
		public function Deferred( callback:Function = null, scope:Object = null )
		{
			super();
			
			this.resolver = new Resolver();

			notifyCallback( callback,	scope );

		}

		/**
		*	 notifyCallback() provides support for special
    *  constructor function handlers.
    *
		*		 @code
		*				return new Deferred( function( dfd:Deferred ):void {
		*
		*			          function onLoad_userDetails( details:Object ):void
		*								{
		*										dfd.resolve( details);
		*										releaseListeners();
		*								}
		*
		*								function onFailed_userDetails( fault:Object ):void
		*								{
		*										dfd.reject( fault );
		*										releaseListeners();
		*								}
		*
		*								function releaseListeners():void
		*								{
		*										userService.removeEventListener(`userDetailsLoaded`,onLoad_userDetails);
		*										userService.removeEventListener(`serviceError`,     onFailed_userDetails);
		*								}
		*
		*								userService.getUserDetails();
		*
		*								userService.addEventListener(`userDetailsLoaded`,onLoad_userDetails);
		*								userService.addEventListener(`serviceError`,onFailed_userDetails);
		*
		*				}).promise;
		*		
		*		 @param callback
		*		 @param scope
		*/
		protected function notifyCallback( callback:Function = null, scope:Object = null ):void
		{
			if ( callback	&& (callback.length == 1) )
			{
				callback.apply( scope, [ this ] );
			}
		}
		
		// ========================================
		// Public methods
		// ========================================
		
		/**
		 * Resolve this Deferred with the specified value.
		 * 
		 * Once a Deferred has been resolved, it is considered to be complete 
		 * and subsequent calls to resolve() or reject() are ignored.
		 */
		public function resolve( value:* ):void
		{
			resolver.resolve( value );
		}
		
		/**
		 * Reject this Deferred with the specified error.
		 * 
		 * Once a Deferred has been rejected, it is considered to be complete
		 * and subsequent calls to resolve() or reject() are ignored.
		 */
		public function reject( error:* ):void
		{
			resolver.reject( error );
		}
	}
}