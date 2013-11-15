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
	public class LogLevel
	{
		/**
		 * Designates informational level messages that are fine grained and most helpful when debugging an application.
		 */
		public static const DEBUG:int = 2;
		
		/**
		 * Designates informational messages that highlight the progress of the application at coarse-grained level.
		 */
		public static const INFO:int = 4;
		
		/**
		 * Designates events that could be harmful to the application operation.
		 */
		public static const WARN:int = 6;
		
		/**
		 * Designates error events that might still allow the application to continue running.
		 */
		public static const ERROR:int = 8;
		
		/**
		 * Designates events that are very harmful and will eventually lead to application failure.
		 */
		public static const FATAL:int = 1000;
	}
}