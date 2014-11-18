package com.codecatalyst.promise
{
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	
	/**
	 * Used to queue callbacks for execution on the next turn of the event loop (using a single Array instance and timer).
	 * 
	 * @private
	 */
	internal class CallbackQueue
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
		private static const queuedCallbacks:Vector.<Callback> = new Vector.<Callback>(1e4, true);
		
		/**
		 * Interval identifier.
		 */
		private var intervalId:int = 0;
		
		/**
		 * # of pending callbacks.
		 */
		private var queuedCallbackCount:uint = 0;
		
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
		 * 
		 * @param callback Callback function.
		 * @param parameters Optional parameters to pass to the callback function.
		 */
		public function schedule( callback:Function, parameters:Array = null ):void
		{
			queuedCallbacks[ queuedCallbackCount++ ] = new Callback( callback, parameters );
			
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
		private function execute():void
		{
			clearInterval( intervalId );
			
			var index:uint = 0;
			while ( index < queuedCallbackCount )
			{
				(queuedCallbacks[ index ] as Callback).execute();
				queuedCallbacks[ index ] = null;
				index++;
			}
			
			queuedCallbackCount = 0;
		}
	}
}