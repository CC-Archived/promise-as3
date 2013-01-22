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
	import mx.rpc.AsyncToken;

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
		 * from another Promises/A implementation) or an AsyncToken.
		 */
		public static function when( value:* ):Promise
		{
			var deferred:Deferred = new Deferred();
			
			if ( value is AsyncToken )
			{
				var token:AsyncToken = value as AsyncToken;
				token.addResponder( new DeferredResponder( deferred ) );
			}
			else
			{
				deferred.resolve( value );
			}
			
			return deferred.promise;
		}
		
		// ========================================
		// Protected properties
		// ========================================
		
		/**
		 * Internal Resolver for this Promise.
		 */
		protected var resolver:Resolver;
		
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
		public function then( onFullfilled:Function = null, onRejected:Function = null ):Promise
		{
			return resolver.then( onFullfilled, onRejected );
		}
	}
}
import com.codecatalyst.promise.Deferred;

import mx.rpc.IResponder;
import mx.rpc.events.FaultEvent;
import mx.rpc.events.ResultEvent;

/**
 * Adapts IResponder interface to delegate result and fault as resolution and rejection of a Deferred.
 * 
 * @private
 */
class DeferredResponder implements IResponder
{
	// ========================================
	// Protected properties
	// ========================================
	
	protected var deferred:Deferred;
	
	// ========================================
	// Constructor
	// ========================================
	
	function DeferredResponder( deferred:Deferred )
	{
		super();
		
		this.deferred = deferred;
	}
	
	// ========================================
	// Public methods
	// ========================================
	
	/**
	 * @inheritDoc
	 */
	public function result( data:Object ):void
	{
		if ( data is ResultEvent )
			deferred.resolve( data.result );
		else
			deferred.resolve( data );
	}
	
	/**
	 * @inheritDoc
	 */
	public function fault( info:Object ):void
	{
		if ( info is FaultEvent )
			deferred.reject( info.fault );
		else
			deferred.reject( info );
	}
}