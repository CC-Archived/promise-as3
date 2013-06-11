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

package com.codecatalyst.promise.adapters
{
	import com.codecatalyst.promise.Promise;
    import com.codecatalyst.promise.inteceptors.DeferredResponder;

    import mx.rpc.AsyncToken;

	/**
	 * AsyncTokenAdapter is an adapter used to enable 
	 * <code>Promise.when()</code> to convert AsyncTokens to Promises.
	 * 
	 * To register this adapter:
	 * <code>Promise.registerAdapter(AsyncTokenAdapter.adapt)</code>
	 *
	 * To unregister this adapter:
	 * <code>Promise.removeAdapter(AsyncTokenAdapter.adapt)</code>
	 */
	public class AsyncTokenAdapter
	{
		/**
		 * Adapts an AsyncToken as a Promise.
		 * 
		 * @param value A candidate value that might be an AsyncToken.
		 * @return A Promise adapting a AsyncToken or null
		 */
		public static function adapt( value:* ):Promise
		{
			const token:AsyncToken = value as AsyncToken;
      return token ? new DeferredResponder( token ).promise : null;
	}
}

