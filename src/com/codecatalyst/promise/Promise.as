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
	 * Promises represent a future value; i.e., a value that may not yet be available.
	 */
	public class Promise
	{
		// ========================================
		// Public static methods
		// ========================================

		/**
		 * Returns a new Promise of the specified value, which may be an
		 * immediate value, a Promise, a foreign Promise (i.e. Promises 
		 * from another Promises/A implementation).
		 *
		 * You can register your own adapters using <code>registerAdapter</code>.
		 *
		 * For example, to deal with AsyncTokens add the following adapter:
		 *
		 * <code>Promise.registerAdapter(AsyncTokenAdapter.adapt)</code>
		 *
		 * Now, when an AsyncToken is passed to <code>when</code>
		 * a specifically adapted Promise is returned.
		 */
		public static function when( value:* ):Promise
		{
			for each (var adapt:Function in adapters)
			{
				const promise:Promise = adapt(value) as Promise;
				if (promise)
					return promise;
			}
			const deferred:Deferred = new Deferred();
			deferred.resolve( value);
			return deferred.promise;
		}

		private static const adapters:Array = [];

		public static function registerAdapter(adapter:Function):void
		{
			if (adapters.indexOf(adapter) == -1)
				adapters.push(adapter);
		}

		public static function removeAdapter(adapter:Function):void
		{
			const index:int = adapters.indexOf(adapter);
			index > -1 && adapters.splice(index, 1);
		}
		
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
		 * Used to specify <code>onFulfilled</code> and <code>onRejected</code>
		 * callbacks that will be notified when the future value becomes 
		 * available.
		 * 
		 * Those callbacks can subsequently transform the value that was 
		 * resolved or the error that was rejected. Each call to then() 
		 * returns a new Promise of that transformed value; i.e., a Promise 
		 * that is resolved with the callback return value or rejected with 
		 * any error thrown by the callback.
		 */
		public function then( onFulfilled:Function = null, onRejected:Function = null ):Promise
		{
			return resolver.then( onFulfilled, onRejected );
		}
	}
}