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
		 *  	watch( <IEventDispatcher>, <resultEventType> || <options> );
		 * 		watch( <IEventDispatcher>, <resultEventType>, <faultEventTypes[]> || <faultEventType> );
		 *  	watch( <IEventDispatcher>, <resultEventType>, <faultEventTypes[]> || <faultEventType>, <progressEventType> );
		 * 		watch( <IEventDispatcher>, <resultEventType>, <faultEventTypes[]> || <faultEventType>, <progressEventType> || <options> );
		 * 
		 * The <options> parameter is a hashmap of optional configuration parameters for 
		 * the addEventListeners() calls:
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
			
			// Build hashMap from variable arguments 
			var options                 : Object = buildWatchOptions(args);
			
			// Parse parameters from hashMap
			var resultType				: String = getObjectPropertyValue( options, "types.result", 	   "result")  	as String,
				faultTypes				: Array  = getObjectPropertyValue( options, "types.faults", 	    ["fault"]) 	as Array,
				progressEventType 		: String = getObjectPropertyValue( options, "types.progress.type",  null) 		as String,
				progressEventProperty	: String = getObjectPropertyValue( options, "types.progress.path")  			as String,
				eventTokenPropertyPath  : String = getObjectPropertyValue( options, "token.path")  					 	as String,
				expectedTokenValue		: * 	 = getObjectPropertyValue( options, "token.expectedValue",  null),
				useCapture			    : *      = getObjectPropertyValue( options, "useCapture", 		    false),
				priority				: *      = getObjectPropertyValue( options, "priority", 			0);
			
			// Call PromiseUtils.listen to build and configure a Deferred for the eventDispatcher
			return listen(	target, 
							resultType, faultTypes, 
							progressEventType, 
							progressEventProperty, 
							Boolean(useCapture), 
							int(priority), 
							eventTokenPropertyPath, 
							expectedTokenValue
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
		 * Promise callbacks will be called with the corresponding Event; consider using Promise'source pipe() method to process the Event into result or fault values. 
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
				if ( !progressEventProperty ) 
				{
					deferred.update( event );
					
				} else {
					var value : * = event.hasOwnProperty(progressEventProperty) ? event[progressEventProperty] : null;
					
					deferred.update.apply(deferred, value ? [value] : null);
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
				
				if ( progressEventType != null )
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
			if ( progressEventType != null )
				dispatcher.addEventListener( progressEventType, update, useCapture, priority );
			
			return deferred.promise;
		}
		
		/**
		 * Introspect target to determine value of property specified by property chain.
		 * Use the defaultVal is chain does not exist in target.  
		 */
		static protected function getObjectPropertyValue(target:Object, chain:String, defaultVal:* = null):* {
				// Support for property chains
			
				var p : * = chain.split(".");
				var r : * = target;
				
				try {
					for (var s:* in p) r = r[p[s]];
				} catch(e:*) { r = defaultVal };
				
				return (!(r as String) || !(r as Number)) ? r : defaultVal;    			
		}
		
		
		
		/**
		 * Simulate method overrides and parse arguments
		 * to build a valid set of watch options. Merge overrides
		 * into a default value hashmap.
		 */
		static protected function buildWatchOptions(args:Array, defaults:Object=null):Object {
			
			// Default configuration options for watch() parameters.
			// This builds a complex hashmap with default values for each expected property.
			
			defaults ||= {                                          
							types      : {  result:"result", faults:["fault"], progress:{ type:null, path:null }},
							token      : {  path:null, expectedValue:null },               
							useCapture : false,                     
							priority   : 0                          
						 };
			
				/**
				 * Safe accessor to arguments by index; failback 
				 * to defaultVal.
				 */
				function _at(j:uint, defaultVal:*=null):*{
					return args.length > j ? args[j] : defaultVal;
				}
				
				/**
				 * Deep copy of source attributes to the target
				 */
				function _merge(target:*, source:Object):* {
					source ||= { };
					
					function isSimple(value:Object):Boolean {
						switch( typeof(value) )
						{
							case "number"  :
							case "string"  :
							case "boolean" : return true;	
							case "object"  : return (value is Date) || (value is Array);
								
							default		   : return false;									
						}
					}
					
					// Source attributes will overwrite existing target attributes
					
					for (var k:* in source)
					{
						var sChild : Object = !isSimple( source[k] )   ? source[k]           : null; 
						var tChild : Object = target.hasOwnProperty(k) ? target[k] as Object : null;
						
							tChild = isSimple(tChild) ? { } : tChild;
						
						target[k] = sChild ? _merge( tChild || { }, sChild ) : source[k];
					}
					
					return target;
				}					
			
			// Parse configuration for the listen() method by merging
			// default options with any overrides.
			
			var results = _merge( defaults, _at(0) as String 	? { types:{ result   : _at(0)         }}  : _at(0) as Object );
				results = _merge( results,  _at(1) as String 	? { types:{ faults   : [_at(1)]       }}  : 
											_at(1) as Array 	? { types:{ faults   : _at(1)    	  }}  : _at(1) as Object );
				results = _merge( results,  _at(2) as String	? { types:{ progress : { type:_at(2) }}}  : _at(2) as Object ); 
			
			return results;			
		}
		
	}
	
}