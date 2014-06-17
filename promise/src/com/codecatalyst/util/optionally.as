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

package com.codecatalyst.util
{
	/**
	 * Executes the specified function, passing as many of the specified 
	 * parameters as the function can accept.
	 * 
	 * @param targetFunction Function to execute.
	 * @param parameters Parameters to potentially pass to the function.
	 * @param requiredParameters Required minimum number of parameters the targetFunction should be passed.
	 * 
	 * @return The function's return value, if applicable.
	 */
	public function optionally( targetFunction:Function, parameters:Array, requiredParameters:int = 0 ):*
	{
		try {
			return targetFunction.apply( null, parameters );
		} catch (e:ArgumentError) {
			var parameterCount:int = Math.max( targetFunction.length, requiredParameters );
			if ( parameterCount < parameters.length ) {
				// only retry if we actually get less parameters:
				return targetFunction.apply( null, parameters.slice( 0, parameterCount ) );
			}
			throw e;
		}
	}
}