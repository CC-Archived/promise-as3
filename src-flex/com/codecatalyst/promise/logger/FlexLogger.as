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

package com.codecatalyst.promise.logger
{
	import mx.logging.Log;

	/**
	 * FlexLogger is a custom logger function that logs messages via Flex's mx.logging.Log.
	 * 
	 * To register this logger:
	 * <code>Promise.registerLogger(FlexLogger.log)</code>
	 *
	 * To unregister this logger:
	 * <code>Promise.unregisterLogger(FlexLogger.log)</code>
	 */
	public class FlexLogger
	{
		// ========================================
		// Public static methods
		// ========================================
		
		/**
		 * Logs a message with the specified category, log level and 
		 * optional parameters.
		 * 
		 * @param category Category
		 * @param level Log level
		 * @param message Message
		 * @param parameters Optional message parameters
		 */
		public static function log( category:String, level:int, message:String, ...parameters ):void
		{
			Log.getLogger( category ).log( level, message, parameters );
		}
	}
}