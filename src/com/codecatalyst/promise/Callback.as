package com.codecatalyst.promise
{
	/**
	* Used to capture a callback closure, along with optional parameters.
	* 
	* @private
	*/
	internal class Callback
	{
		// ========================================
		// Protected properties
		// ========================================
		
		/**
		 * Callback closure.
		 */
		private var closure:Function;
		
		/**
		 * Callback parameters.
		 */
		private var parameters:Array;
		
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
}