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
	 * Adapts IResponder interface to delegate result and fault as resolution and rejection of a Deferred.
	 *
	 */
	public class AsyncTokenAdapter
	{

		public static function adapt(value:*):Promise
		{
			const token:AsyncToken = value as AsyncToken;
			if (token)
			{
				const deferred:Deferred = new Deferred();
				token.addResponder(new DeferredResponder(deferred));
				return deferred.promise;
			}
			return null;
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
		data is ResultEvent
			? deferred.resolve( data.result )
			: deferred.resolve( data );
	}

	/**
	 * @inheritDoc
	 */
	public function fault( info:Object ):void
	{
		info is FaultEvent
			? deferred.reject( info.fault )
			: deferred.reject( info );
	}
}