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
	 * Executes the specified callback function on the next turn of the event loop.
	 */
	public function nextTick( callback:Function, parameters:Array = null ):void
	{
		CallbackQueue.instance.schedule( callback, parameters );
	}
}

import flash.utils.clearInterval;
import flash.utils.setInterval;

/**
 * Used to queue callbacks for execution on the next turn of the event loop (using a single timer).
 * 
 * @private
 */
class CallbackQueue
{
	// ========================================
	// Public properties
	// ========================================
	
	/**
	 * Singleton instance accessor.
	 */
	public static const instance:CallbackQueue = new CallbackQueue();
	
	// ========================================
	// Protected properties
	// ========================================
	
	/**
	 * Queued Callback(s).
	 */
	protected const queuedCallbacks:Array = new Array(1e4);

	/**
	 * Count for # of callbacks still pending in the queue
	 */
	protected var queuedCallbackCount : uint = 0;

	/**
	 * Interval identifier.
	 */
	protected var intervalId:int = 0;
	
	// ========================================
	// Constructor
	// ========================================
	
	public function CallbackQueue()
	{
		super();
	}
	
	// ========================================
	// Public methods
	// ========================================
	
	/**
	 * Add a callback to the end of the queue, to be executed on the next turn of the event loop.
	 */
	public function schedule( closure:Function, parameters:Array = null ):void
	{
		queuedCallbacks[ queuedCallbackCount++ ] = new Callback( closure, parameters );
		
		if ( queuedCallbackCount == 1 )
		{
			intervalId = setInterval( execute, 0 );
		}
	}
	
	// ========================================
	// Protected methods
	// ========================================
	
	/**
	 * Execute any queued callbacks and clear the queue.
	 */
	protected function execute():void
	{
			var index : uint = 0;

			clearInterval( intervalId );

			while( index < queuedCallbackCount )
			{
				(queuedCallbacks[ index ] as Callback).execute();
				queuedCallbacks[ index ] = null;

				index += 1;
			}

			queuedCallbackCount = 0;
	}
}

/**
 * Used to capture a callback closure, along with optional parameters.
 * 
 * @private
 */
class Callback
{
	// ========================================
	// Protected properties
	// ========================================
	
	/**
	 * Callback closure.
	 */
	protected var closure:Function;
	
	/**
	 * Callback parameters.
	 */
	protected var parameters:Array;
	
	// ========================================
	// Constructor
	// ========================================
	
	public function Callback( closure:Function, parameters:Array = null )
	{
		super();
		
		this.closure = closure;
		this.parameters = parameters;
	}
	
	// ========================================
	// Public methods
	// ========================================
	
	/**
	 * Execute this callback.
	 */
	public function execute():void
	{
		closure.apply( null, parameters );
	}
}