package com.codecatalyst.promise
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	/**
	 * Create a callback list using the following parameters:
	 *
	 *	flags:	an optional list of space-separated flags that will change how
	 *			the callback list behaves
	 *
	 * By default a callback list will act like an event callback list and can be
	 * "fired" multiple times.
	 *
	 * Possible flags:
	 *
	 *	once:			will ensure the callback list can only be fired once (like a Deferred)
	 *
	 *	memory:			will keep track of previous values and will call any callback added
	 *					after the list has been fired right away with the latest "memorized"
	 *					values (like a Deferred)
	 *
	 *	unique:			will ensure a callback can only be added once (no duplicate in the list)
	 *
	 *	stopOnFalse:	interrupt callings when a callback returns false
	 *
	 */
	public class Callbacks extends EventDispatcher
	{
		/**
		 * Internal state change Event type.
		 */
		internal static const STATE_CHANGED:String = "stateChanged";
		
		
		[Bindable( "stateChanged" )]
		/**
		 * Is it disabled?
		 */
		public function get disabled() : Boolean {	return !list;		}
		
		[Bindable( "stateChanged" )]
		/**
		 * Is it locked?
		 */
		public function get locked() : Boolean 	 {	return !stack;		}
		
		[Bindable( "stateChanged" )]
		/**
		 * To know if the callbacks have already been called at least once
		 */
		public function get fired() : Boolean  	 {	return !!memory;	}		
		

		public function get stopped() : Boolean  
		{ 
			return memory === true; 
		}
		public function set stopped(val:Boolean):void
		{
			if (!stopped && val) {
				
				// Only stop if not already stopped.
				memory = true;
			}
		}
			
		
		/**
		 * Constructor
		 */
		public function Callbacks( flags:String=null ) {
			
			// Convert flags from String-formatted to Object-formatted
			
			this.flags = flags ? ( flagsCache[ flags ] || createFlags( flags ) ) : {};
			
			this.list  = [ ];
			this.stack = [ ];
			
			this.memory= null;
		}
		
		/**
		 * Control if a given callback is in the list
		 */
		public function has( fn ):Boolean {
			if ( list ) {
				var i = 0,
					length = list.length;
				
				for ( ; i < length; i++ ) 
				{
					if ( fn === list[ i ] ) 
					{
						return true;
					}
				}
			}
			return false;
		}
		
		/**
		 * Remove all callbacks from the list
		 */
		public function empty():Callbacks {
			list = [];
			dispatchEvent( new Event( STATE_CHANGED ) );
			
			return this;
		}
		
		/**
		 * Have the list do nothing anymore
		 */	
		public function disable():Callbacks {
			list = stack = memory = undefined;
			
			dispatchEvent( new Event( STATE_CHANGED ) );
			
			return this;
		}
		
		/**
		 * Lock the list in its current state
		 */
		public function lock():Callbacks {
			stack = undefined;
			if ( !memory || stopped ) {
				
				disable();
				
			} else {
				
				dispatchEvent( new Event( STATE_CHANGED ) );
			}
			
			return this;
		}
		
		/**
		 * Add a callback or a collection of callbacks to the list
		 */
		public function add(...args):Callbacks {
			if ( list ) {
				var length = list.length;
				
				addCallbacks( args );
				
				// Do we need to add the callbacks to the
				// current firing batch?
				if ( firing )
				{
					firingLength = list.length;
					
				} else if ( memory && !stopped ) {
					
					// With memory, if we're not firing then
					// we should call right away, unless previous
					// firing was halted (stopOnFalse)
					
					firingStart = length;
					fireCallbacks( memory[ 0 ], memory[ 1 ] );
				}
			}
			return this;
		}
		
		/**
		 * Remove a callback from the list
		 */
		public function remove(...args):Callbacks {
			if ( list ) 
			{
				var argLength = args.length,
					argIndex  = 0;
				
				for ( ; argIndex < argLength ; argIndex++ ) 
				{
					for ( var i = 0; i < list.length; i++ ) 
					{
						if ( args[ argIndex ] === list[ i ] ) 
						{
							// Handle firingIndex and firingLength
							if ( firing ) 
							{
								if ( i <= firingLength ) 
								{
									firingLength--;
									if ( i <= firingIndex ) 
									{
										firingIndex--;
									}
								}
							}
							
							// Remove the element
							list.splice( i--, 1 );
							
							// If we have some unicity property then
							// we only need to do this once
							if ( flags.unique ) 	break;
						}
					}
				}
			}
			return this;
		}
		
		/**
		 * Call all callbacks with the given context and arguments
		 */
		public function fireWith( context, args ):Callbacks {
			if ( stack ) 
			{
				if ( firing ) 
				{
					if ( !flags.once ) 
					{
						stack.push( [ context, args ] );
					}
					
				} else if ( !(flags.once && memory) ) 
				{
					fireCallbacks( context, args );
					
				}
			}
			return this;
		}
		
		/**
		 * Call all the callbacks with the given arguments
		 */
		public function fire(...args):Callbacks {
			fireWith( this, args );
			return this;
		}
		
		// ****************************************************************************
		// Protected Methods
		// ****************************************************************************
		
		
		/**
		 * Add one or several callbacks to the list 
		 */
		protected function addCallbacks( args ):void {
			
			for ( var i:uint = 0, length:uint = args.length; i < length; i++ ) 
			{
				var elem : * = args[ i ];
				
				if ( elem is Array ) 	
				{
					addCallbacks( elem );	// Inspect recursively
				}
				else if ( elem is Function ) 
				{
					// Add if not in unique mode and callback is not in
					if ( !flags.unique || !has( elem ) ) {
						list.push( elem );
					}
				}
			}
		}
		
		protected function fireCallbacks( context, args ):void {
			args         = args || [];
			memory       = !flags.memory || [ context, args ];
			firing       = true;
			firingIndex  = firingStart || 0;
			firingStart  = 0;
			firingLength = list.length;
			
			try {
				dispatchEvent( new Event( STATE_CHANGED ) );
				
				for ( ; list && firingIndex < firingLength; firingIndex++ ) {
					if ( list[ firingIndex ].apply( context, args ) === false && flags.stopOnFalse ) {
						stopped = true; // Mark as halted
						break;
					}
				}
			}
			finally {
				
				firing = false;
				
				if ( list ) 
				{
					if ( !flags.once ) 
					{
						if ( stack && stack.length ) 
						{
							memory = stack.shift();
							fire( memory[ 0 ], memory[ 1 ] );
						}
						
					} else if ( stopped )  {
						
						this.disable();
						
					} else {
						
						list = [];
					}
				}
			
				dispatchEvent( new Event( STATE_CHANGED ) );
			}
		}

		// ****************************************************************************
		// Private Attribtues
		// ****************************************************************************
		
		/**
		 * Actual callback list
		 */
		private var list  : Array 	= [ ];
		
		/**
		 * Stack of fire calls for repeatable lists
		 */
		private var stack : Array   = [ ];
		
		/**
		 * Last fire value (for non-forgettable lists)
		 */
		private var memory : *;
		
		
		/**
		 * Flag to know if list is currently firing
		 */
		private var firing : Boolean = false;

		/**
		 * First callback to fire (used internally by add and fireWith)
		 */
		private var firingStart : *;

		/**
		 * End of the loop when firing
		 */
		private var firingLength : uint;

		/**
		 * Index of currently firing callback (modified by remove if needed)
		 */
		private var firingIndex : uint;

		/**
		 * A list of space-separated flags that will change how
		 * the callback list behaves
		 */
		private var flags : Object	= { };
		
		
		
		// ****************************************************************************
		// Static Variable and Methods
		// ****************************************************************************
		
		/**
		 * Convert String-formatted flags into Object-formatted ones and store in cache
		 * @private 
		 */
		static private function createFlags( flags:String ):Object {
			
			var results : Object = flagsCache[ flags ] = { },
				list    : Array  = flags.split( /\s+/ ); 
			
			for ( var i:uint = 0, length:uint = list.length; i < length; i++ ) {
				results[ list[i] ] = true;
			}
			return results;
		}

		/**
		 * Global lookup between string and object flag options
		 * @private 
		 */
		static private var flagsCache : Object = { };
		
	}
}