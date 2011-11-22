package com.codecatalyst.promise
{
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	
	/**
	 * Utility methods related to Promises and adapting Flash and ActionScript asynchronous operations for use with Promises.
	 * Possible invocations:
	 * 
	 * @see com.codecatalyst.util.AsyncTokenUtil#createPromise()
	 * 
	 * @author John Yanarella
	 * @author Thomas Burleson
	 * 
	 */
	public class PromiseUtil
	{

		/**
		 * Variable argument method that supports condensed syntax (ala jQuery $.ajax styles) for creating a deferred promise 
		 * for a specified event dispatcher. Here are the supported invocations:
		 * 
		 *  	watch( <IEventDispatcher>, <options> );
		 *  	watch( <IEventDispatcher>, <resultEventType> ); 
		 * 		watch( <IEventDispatcher>, <resultEventType>, <faultEventTypes[]>, );
		 *  	watch( <IEventDispatcher>, <resultEventType>, <faultEventTypes[]>, <options> );
		 * 
		 * The <options> parameter is a hashmap of optional key/value pairs:
		 * 
		 *   { 
		 * 		types : {
		 * 					result 		: <string>,
		 * 					faults 		: [ <string> ],
		 * 					progress	: {
		 * 									type : <string>,
		 * 									path : <string>
		 * 				 				  }
		 * 				 },
		 * 		token  : {
		 * 					path          : <string>,
		 * 					expectedValue : *
		 *               },
		 * 		useCapture : <boolean>,
		 * 	    priority   : <int>
		 *   }
		 * 
		 * @param target IEventDispatcher which the Deferred will internally attach specified listeners
		 * 
		 * @see com.codecatalyst.util.promise.jQuery#jQuery()
		 *
		 */
		public static function watch( target:IEventDispatcher, ...args):Promise {
			if (target == null) return null;
			
				function buildOptions():Object {
					
					function getArg(j:uint, defaultVal:*=null):*{
						return args.length > j ? args[j] : defaultVal;
					}
					
					var arg1 : String = getArg(0) as String,
						arg2 : Array  = getArg(1) as Array;
					
					return 	arg1 && arg2 	? 	getArg(2) as Object || { }  :
							arg1         	? 	getArg(1) as Object || { }  :  getArg(0) as Object || { };
						
				}
			
			// Build hashMap from variable arguments 
				
			var options                 : Object = buildOptions();
			
			// Parse parameters from hashMap
			
			var resultType				: String = getObjectPropertyValue( options, "types.result", "result")   as String,
				faultTypes				: Array  = getObjectPropertyValue( options, "types.faults", ["fault"])  as Array,
				progressEventType 		: String = getObjectPropertyValue( options, "types.progress.type") 	 	as String,
				progressEventProperty	: String = getObjectPropertyValue( options, "types.progress.path") 	 	as String,
				eventTokenPropertyPath  : String = getObjectPropertyValue( options, "token.path") 				as String,
				expectedTokenValue		: * 	 = getObjectPropertyValue( options, "token.expectedValue"),
				useCapture			    : *      = getObjectPropertyValue( options, "useCapture", 	false),
				priority				: *      = getObjectPropertyValue( options, "priority", 	0);
			
			// Call PromiseUtils.listen to build and configure a Deferred for the eventDispatcher
			
			return listen(	target, 
							resultType, faultTypes, 
							progressEventType, progressEventProperty, 
							Boolean(useCapture), int(priority), 
							eventTokenPropertyPath, expectedTokenValue
						);
		}
		
		/**
		 * Creates a Promise that adapts an asynchronous operation that uses Event based notification, given
		 * the event dispatcher, a single result event type, an Array of potential fault types, and an optional progress type.
		 * 
		 * NOTE: Event dispatchers that dispatch Events corresponding to multiple concurrent asynchronous operations cannot be adapted with this approach unless
		 * there is a 'token' property accessible via the Event or Event target which can be used to correlate an operation with its Events.
		 * In this case, use the optional eventTokenProperty and eventTokenPropertyPath parameters to specify this token and its path (in dot notation) relative to the Events.
		 * 
		 * Promise callbacks will be called with the corresponding Event; consider using Promise's pipe() method to process the Event into result or fault values. 
		 * @see com.codecatalyst.util.promise.Promise#pipe()
		 * 
		 * NOTE: It is critical to specify the result event type and all possible fault event types to avoid introducing memory leaks.
		 */
		public static function listen( dispatcher:IEventDispatcher, resultEventType:String, faultEventTypes:Array, progressEventType:String = null, progressEventProperty:String = null, useCapture:Boolean = false, priority:int = 0, eventTokenPropertyPath:String = null, expectedTokenValue:* = null ):Promise
		{
			var deferred:Deferred = new Deferred();
			
			// Check for a correlating token value, if applicable.
			function checkToken( event:Event ):Boolean
			{
				if ( eventTokenPropertyPath != null )
				{
					var token:* = getObjectPropertyValue( event, eventTokenPropertyPath );
					
					return ( token == expectedTokenValue );
				}
				
				return true;
			}
			
			// Result event handling closure.
			function resolve( event:Event ):void
			{
				if ( checkToken(event) )
				{
					deferred.resolve( event );
					release();
				}
			}
			
			// Fault event handling closure.
			function reject( event:Event ):void
			{
				if ( checkToken(event) )
				{
					deferred.reject( event );
					release();
				}
			}
			
			// Progress event handling closure.
			function update( event:Event ):void
			{
				if ( checkToken(event) )
				{
					deferred.update( event[ progressEventProperty ] );
				}
			}
			
			// Clean-up logic - required to avoid memory leaks.
			function release():void
			{
				dispatcher.removeEventListener( resultEventType, resolve, useCapture );
				
				for each ( var faultEventType:String in faultEventTypes )
				{
					dispatcher.removeEventListener( faultEventType, reject, useCapture );
				}
				
				if ( ( progressEventType != null ) && ( progressEventProperty != null ) )
					dispatcher.removeEventListener( progressEventType, update, useCapture );
			}
			
			// Listen for result event.
			dispatcher.addEventListener( resultEventType, resolve, useCapture, priority );
			
			// Listen for fault event.
			for each ( var faultEventType:String in faultEventTypes )
			{
				dispatcher.addEventListener( faultEventType, reject, useCapture, priority );
			}
			
			// Listen for progress event, if applicable.
			if ( ( progressEventType != null ) && ( progressEventProperty != null ) )
				dispatcher.addEventListener( progressEventType, update, useCapture, priority );
			
			return deferred.promise;
		}
		
		static protected function getObjectPropertyValue(target:Object, chain:String, defaultVal:* = null):* {
				// Support for property chains
			
				var p : * = chain.split(".");
				var r : * = target;
				
				try {
					for (var s:* in p) r = r[p[s]];
				} catch(e:*) { r = target };
				
				return (!(r as String) || !(r as Number)) ? r : defaultVal;    			
		}

	}
	
}