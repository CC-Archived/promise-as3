/*
* Copyright (c) 2010 the original author or authors
*
* Permission is hereby granted to use, modify, and distribute this file
* in accordance with the terms of the license agreement accompanying it.
*
* @author  Thomas Burleson
*/
package com.codecatalyst.promise.tests
{
  import com.codecatalyst.promise.Deferred;
  import com.codecatalyst.promise.Promise;
  import com.codecatalyst.promise.jQuery;
  
  import org.flexunit.Assert;

  /**
   * Imported the QUnit javascript tests for $ Promises. 
   * 
   * @see https://github.com/jquery/jquery/blob/master/test/unit/deferred.js
   * 
   * Changes from javascript to AS#:
   * 
   *   1) isResolved(), isRejected()          --> resolved, rejected
   *   2) Deferred::state()   --> Deferred.state
   *   3) Deferred::promise() --> Deferred.promise
   * 
   *   Since not conformant with AS3 developer expectations:
   * 
   *   4) `this` context in Deferred.then() is NOT the deferred instance
   *      - only supported in the new Deferred( function(dfd) { this === dfd; }); context
   * 
   *   5) test( "jQuery.Deferred.pipe - context") 	disabled 
   *   6) test("jQuery.when - joined") 				disabled
   * 
   * The primary, essential difference between the AS3 and Javascript implementation is
   * the `this` context in the Deferred/Promise handlers.
   * 
   * 		In AS3, the `this` context does NOT refer to the Deferred/Promise instance. Rather the
   * 		`this` scope references the context where the function was defined!
   * 
   */
  public class TestjQuery
  {   
    // *****************************************************************************
    // Static Methods 
    // *****************************************************************************
    
    [BeforeClass] public static function setUpBeforeClass() :void {   }
    [AfterClass]  public static function tearDownAfterClass() :void {   }

    // *****************************************************************************
    // Public Configuration Methods 
    // *****************************************************************************

    [Before]
    public function setUp():void
    {
      jQuery = com.codecatalyst.promise.jQuery();
	  
	  (function initCounters():void {
		  alwaysHitCount      = 0;
		  alwaysReponse       = null;
	  }());
    }
    
    [After]
    public function tearDown():void
    {
      jQuery = null;
    }
    
    // *****************************************************************************
    // Public Tests imported from Javascript Deferred tests 
    //
    // @see https://github.com/jquery/jquery/blob/master/test/unit/deferred.js
    //
    // *****************************************************************************
    
    [Test(order=1, description="Port of jQuery QUnit tests: deferred.js")]
    public function test_jQueryDeferred():void 
    {

		test("jQuery.Deferred", function() {
			
			expect( 22 );
			
			createDeferred().resolve().then( function() {
				ok( true , "Success on resolve" );
				ok( dfd.resolved, "Deferred is resolved" );
				strictEqual( dfd.state, "resolved", "Deferred is resolved (state)" );
			}, function() {
				ok( false , "Error on resolve" );
			}).always( function() {
				ok( true , "Always callback on resolve" );
			});
			
			createDeferred().reject().then( function() {
				ok( false , "Success on reject" );
			}, function() {
				ok( true , "Error on reject" );
				ok( dfd.rejected, "Deferred is rejected" );
				strictEqual( dfd.state, "rejected", "Deferred is rejected (state)" );
			}).always( function() {
				ok( true , "Always callback on reject" );
			});
			
			createDeferred( function( defer ) {
				ok( this === defer , "Defer passed as this & first argument" );
				defer.resolve( "done" );
			}).then( function( value ) {
				strictEqual( value , "done" , "Passed function executed" );
			});
			
			jQuery.each( "resolve reject".split( " " ), function( _, change ) {
				createDeferred( function( defer ) {
					strictEqual( defer.state, "pending", "pending after creation" );
					var checked = 0;
					defer.progress(function( value ) {
						strictEqual( value, checked, "Progress: right value (" + value + ") received" );
					});
					for( checked = 0; checked < 3 ; checked++ ) {
						defer.notify( checked );
					}
					strictEqual( defer.state, "pending", "pending after notification" );
					defer[ change ]();
					notStrictEqual( defer.state, "pending", "not pending after " + change );
					defer.notify();
				});
			});
			
		});
		
		
		test( "jQuery.Deferred - chainability", function() {
			
			var methods = "resolve reject notify done fail progress always".split( " " ),
			defer = jQuery.Deferred();
			
			expect( methods.length );
			
			jQuery.each( methods, function( _, method ) {
				var object = { m: defer[ method ] };
				strictEqual( object.m(), defer, method + " is chainable" );
			});
		});
		
		test( "jQuery.Deferred.pipe - filtering (done)", function() {
			
			expect(4);
			
			var defer = jQuery.Deferred(),
			piped = defer.pipe(function( a, b ) {
				return a * b;
			}),
			value1,
			value2,
			value3;
			
			piped.done(function( result ) {
				value3 = result;
			});
			
			defer.done(function( a, b ) {
				value1 = a;
				value2 = b;
			});
			
			defer.resolve( 2, 3 );
			
			strictEqual( value1, 2, "first resolve value ok" );
			strictEqual( value2, 3, "second resolve value ok" );
			strictEqual( value3, 6, "result of filter ok" );
			
			jQuery.Deferred().reject().pipe(function() {
				ok( false, "pipe should not be called on reject" );
			});
			
			jQuery.Deferred().resolve().pipe( jQuery.noop ).done(function( value ) {
				strictEqual( value, undefined, "pipe done callback can return undefined/null" );
			});
			
		});
		
		test( "jQuery.Deferred.pipe - filtering (fail)", function() {
			
			expect(4);
			
			var defer = jQuery.Deferred(),
			piped = defer.pipe( null, function( a, b ) {
				return a * b;
			} ),
			value1,
			value2,
			value3;
			
			piped.fail(function( result ) {
				value3 = result;
			});
			
			defer.fail(function( a, b ) {
				value1 = a;
				value2 = b;
			});
			
			defer.reject( 2, 3 );
			
			strictEqual( value1, 2, "first reject value ok" );
			strictEqual( value2, 3, "second reject value ok" );
			strictEqual( value3, 6, "result of filter ok" );
			
			jQuery.Deferred().resolve().pipe( null, function() {
				ok( false, "pipe should not be called on resolve" );
			} );
			
			jQuery.Deferred().reject().pipe( null, jQuery.noop ).fail(function( value ) {
				strictEqual( value, undefined, "pipe fail callback can return undefined/null" );
			});
			
		});
		
		test( "jQuery.Deferred.pipe - filtering (progress)", function() {
			
			expect(3);
			
			var defer = jQuery.Deferred(),
			piped = defer.pipe( null, null, function( a, b ) {
				return a * b;
			} ),
			value1,
			value2,
			value3;
			
			piped.progress(function( result ) {
				value3 = result;
			});
			
			defer.progress(function( a, b ) {
				value1 = a;
				value2 = b;
			});
			
			defer.notify( 2, 3 );
			
			strictEqual( value1, 2, "first progress value ok" );
			strictEqual( value2, 3, "second progress value ok" );
			strictEqual( value3, 6, "result of filter ok" );
			
		});
		
		test( "jQuery.Deferred.pipe - deferred (done)", function() {
			
			expect(3);
			
			var defer = jQuery.Deferred(),
			piped = defer.pipe(function( a, b ) {
				return jQuery.Deferred(function( defer ) {
					defer.reject( a * b );
				});
			}),
			value1,
			value2,
			value3;
			
			piped.fail(function( result ) {
				value3 = result;
			});
			
			defer.done(function( a, b ) {
				value1 = a;
				value2 = b;
			});
			
			defer.resolve( 2, 3 );
			
			strictEqual( value1, 2, "first resolve value ok" );
			strictEqual( value2, 3, "second resolve value ok" );
			strictEqual( value3, 6, "result of filter ok" );
			
		});
		
		test( "jQuery.Deferred.pipe - deferred (fail)", function() {
			
			expect(3);
			
			var defer = jQuery.Deferred(),
			piped = defer.pipe( null, function( a, b ) {
				return jQuery.Deferred(function( defer ) {
					defer.resolve( a * b );
				});
			} ),
			value1,
			value2,
			value3;
			
			piped.done(function( result ) {
				value3 = result;
			});
			
			defer.fail(function( a, b ) {
				value1 = a;
				value2 = b;
			});
			
			defer.reject( 2, 3 );
			
			strictEqual( value1, 2, "first reject value ok" );
			strictEqual( value2, 3, "second reject value ok" );
			strictEqual( value3, 6, "result of filter ok" );
			
		});
		
		test( "jQuery.Deferred.pipe - deferred (progress)", function() {
			
			expect(3);
			
			var defer = jQuery.Deferred(),
			piped = defer.pipe( null, null, function( a, b ) {
				return jQuery.Deferred(function( defer ) {
					defer.resolve( a * b );
				});
			} ),
			value1,
			value2,
			value3;
			
			piped.done(function( result ) {
				value3 = result;
			});
			
			defer.progress(function( a, b ) {
				value1 = a;
				value2 = b;
			});
			
			defer.notify( 2, 3 );
			
			strictEqual( value1, 2, "first progress value ok" );
			strictEqual( value2, 3, "second progress value ok" );
			strictEqual( value3, 6, "result of filter ok" );
			
		});
		
		/*
		* Currently not supported in ActionScript3 implementation
		*
		test( "jQuery.Deferred.pipe - context", function() {
		
		expect(4);
		
		var context = {};
		
		jQuery.Deferred().resolveWith( context, [ 2 ] ).pipe(function( value ) {
		return value * 3;
		}).done(function( value ) {
		strictEqual( dfd, context, "custom context correctly propagated" );
		strictEqual( value, 6, "proper value received" );
		});
		
		var defer = jQuery.Deferred(),
		piped = defer.pipe(function( value ) {
		return value * 3;
		});
		
		defer.resolve( 2 );
		
		piped.done(function( value ) {
		strictEqual( defer.promise, piped, "default context gets updated to latest defer in the chain" );
		strictEqual( value, 6, "proper value received" );
		});
		
		});
		*/
		
		test( "jQuery.when" , function() {
			
			expect( 23 );
			
			// Some other objects
			jQuery.each( {
				
				"an empty string": "",
				"a non-empty string": "some string",
				"zero": 0,
				"a number other than zero": 1,
				"true": true,
				"false": false,
				"null": null,
				"undefined": undefined,
				"a plain object": {}
				
			} , function( message , value ) {
				
				ok( jQuery.when( value ).done( function( resolveValue ) {
					strictEqual( resolveValue , value , "Test the promise was resolved with " + message );
				}) is Promise, "Test " + message + " triggers the creation of a new Promise" );
				
			} );
			
			ok(  jQuery.when().done( function( resolveValue ) {
				strictEqual( resolveValue , undefined , "Test the promise was resolved with no parameter" );
			}) is Promise, "Test calling when with no parameter triggers the creation of a new Promise" );
			
			var cache, i;
			
			for( i = 1 ; i < 4 ; i++ ) {
				jQuery.when( cache || jQuery.Deferred( function(dfd) {
					this.resolve( i );
				}) ).done(function( value ) {
					strictEqual( value , 1 , "Function executed" + ( i > 1 ? " only once" : "" ) );
					cache = value;
				});
			}
			
		});
		
		/*		
		 *
		 *
		test("jQuery.when - joined", function() {
			
			expect(53);
			
			var deferreds = {
				value: 1,
				success: jQuery.Deferred().resolve( 1 ),
				error: jQuery.Deferred().reject( 0 ),
				futureSuccess: jQuery.Deferred().notify( true ),
				futureError: jQuery.Deferred().notify( true ),
				notify: jQuery.Deferred().notify( true )
			},
			willSucceed = {
				value: true,
				success: true,
				futureSuccess: true
			},
			willError = {
				error: true,
				futureError: true
			},
			willNotify = {
				futureSuccess: true,
				futureError: true,
				notify: true
			};
			
			jQuery.each( deferreds, function( id1, defer1 ) {
				jQuery.each( deferreds, function( id2, defer2 ) {
					var shouldResolve  = willSucceed[ id1 ] && willSucceed[ id2 ],
						shouldError    = willError[ id1 ] || willError[ id2 ],
						shouldNotify   = willNotify[ id1 ] || willNotify[ id2 ],
						expected       = shouldResolve ? [ 1, 1 ] : [ 0, undefined ],
						expectedNotify = shouldNotify && [ willNotify[ id1 ], willNotify[ id2 ] ],
						code           = id1 + "/" + id2;
					
					var promise = jQuery.when( defer1, defer2 ).done(function( a, b ) {
						if ( shouldResolve ) {
							deepEqual( [ a, b ], expected, code + " => resolve" );
						} else {
							ok( false ,  code + " => resolve" );
						}
					}).fail(function( a, b ) {
						if ( shouldError ) {
							deepEqual( [ b, a ], expected, code + " => reject" );
						} else {
							ok( false ,  code + " => reject" );
						}
					}).progress(function progress( a, b ) {
						deepEqual( [ a, b ], expectedNotify, code + " => progress" );
					});
				} );
			} );
			deferreds.futureSuccess.resolve( 1 );
			deferreds.futureError.reject( 0 );
		});
	   */		
		
		confirmExpected();
    }
     
    
    // *****************************************************************************
    // Simulation of QUnit methods
    // *****************************************************************************
    
	protected function test(title,testFunc) {
		trace("test( " + title + " )");
		testFunc();
	}

	protected function expect(val:uint):void {
      expectedChecks += val;
    }
	
	
    protected function ok(value:Boolean,message:String):void  
    {   
      alwaysHitCount++;   
      Assert.assertTrue(message,value);   
    }
    
    protected function strictEqual(state:*,value:*, message:String):void  
    {   
      alwaysHitCount++;
      
      state = !(state is Array)         ? state   :
           (state as Array).length == 0   ? null    :
           (state as Array).length == 1   ? state[0]  : state;
      
      Assert.assertStrictlyEquals( message, state, value);  
    }
    protected function notStrictEqual(state:*,value:*, message:String):void   
    {   
      alwaysHitCount++;   
      Assert.assertFalse(message,state === value);  
    }
    
	protected function confirmExpected():void {
		Assert.assertEquals("expected validations = "+ expectedChecks, expectedChecks, alwaysHitCount );
	}
	
    // *****************************************************************************
    // Private Properties 
    // *****************************************************************************

	private function createDeferred(...args):Deferred {
		return this.dfd = jQuery.Deferred.apply(null,args);
	}
    
	private var dfd      		:Deferred;
    private var jQuery      	:Object;
    
    private var expectedChecks  :uint = 0;
	
    private var alwaysHitCount  :int = 0;
    private var alwaysReponse   :*   = null;
    
    
  }
}