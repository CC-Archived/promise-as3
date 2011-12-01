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
	import com.codecatalyst.promise.Promise;
	import com.codecatalyst.promise.jQuery;
	
	import org.flexunit.Assert;

	/**
	 * Imported the QUnit javascript tests for jQuery Promises. 
	 * 
	 * @see https://github.com/jquery/jquery/blob/master/test/unit/deferred.js
	 * 
	 * Issues wrt jQuery code:
	 * 
	 *   1) isResolved(), isRejected()          --> resolved, rejected
	 *   2) `this` context in Deferred.then() is NOT the deferred instance
	 *   3) Unable to get Test 10 to work properly as expected
	 *
	 */
	public class TestjQuery
	{		
		// *****************************************************************************
		// Static Methods 
		// *****************************************************************************
		
		[BeforeClass]	public static function setUpBeforeClass()	:void {		}
		[AfterClass]	public static function tearDownAfterClass()	:void {		}

		// *****************************************************************************
		// Public Configuration Methods 
		// *****************************************************************************

		[Before]
		public function setUp():void
		{
			$ = jQuery();
			initCounters();
		}
		
		[After]
		public function tearDown():void
		{
			$ = null;
		}
		
		// *****************************************************************************
		// Public Tests imported from Javascript Deferred tests 
		//
		// @see https://github.com/jquery/jquery/blob/master/test/unit/deferred.js
		//
		// *****************************************************************************
		
		[Test(order=1, description="$.Deferred")]
		public function test_jQueryDeferred():void 
		{
			initCounters();
			expect( 22 );
		
			var dfd = $.Deferred().resolve()
			dfd.then( function() {
				ok( true , "Success on resolve" );
				ok( dfd.resolved, "Deferred is resolved" );
				strictEqual( dfd.state, "resolved", "Deferred is resolved (state)" );
			}, function() {
				ok( false , "Error on resolve" );
			}).always( function() {
				ok( true , "Always callback on resolve" );
			});
			
			dfd = $.Deferred().reject();
			dfd.then( function() {
				ok( false , "Success on reject" );
			}, function() {
				ok( true , "Error on reject" );
				ok( dfd.rejected, "Deferred is rejected" );
				strictEqual( dfd.state, "rejected", "Deferred is rejected (state)" );
			}).always( function() {
				ok( true , "Always callback on reject" );
			});
			
			dfd = $.Deferred( function( defer ) {
				ok( this === defer , "Defer passed as this & first argument" );
				this.resolve( "done" );
			}).then( function( value ) {
				strictEqual( value , "done" , "Passed function executed" );
			});
		
			$.each( "resolve reject".split( " " ), function( _, change ) {
				$.Deferred( function( defer ) {
					var checked = 0;
					
					defer.progress(function( value ) {
						strictEqual( value, checked, "Progress: right value (" + value + ") received" );
					});
					
					strictEqual( defer.state, "pending", "pending after creation" );
					
					for( checked = 0; checked < 3 ; checked++ ) {
						defer.notify( checked );
					}
					strictEqual( defer.state, "pending", "pending after notification" );
					defer[ change ]();
					
					notStrictEqual( defer.state, "pending", "not pending after " + change );
					defer.notify();
				});
			});
			
			confirmExpected();
		}
				
		
		[Test(order=2, description="$.Deferred - chainability")]
		public function test_jQueryDeferred_chainability():void 
		{
			
			var methods = "resolve reject notify cancel".split( " " ),
				defer   = $.Deferred();
			
			expect( methods.length );
			
			$.each( methods, function( _, method ) {
				var object = { m: defer[ method ] };
				strictEqual( object.m(), defer, method + " is chainable" );
			});
			
			confirmExpected();
		}
		
		
		[Test(order=3, description="$.Deferred - filtering (done)")]
		public function test_jQueryDeferred_filterWithResolve():void 
		{
			
			expect(4);
			
			var defer = $.Deferred(),
				piped = defer.pipe(function( a, b ) {
					return a * b;
				}),
				value1,
				value2,
				value3;
			
			piped.done(function( c ) {
				value3 = c;
			});
			
			defer.done( function(a,b) {
				value1 = a;
				value2 = b;
			});
			
			defer.resolve( 2, 3 );
			
			strictEqual( value1, 2, "first resolve value ok" );
			strictEqual( value2, 3, "second resolve value ok" );
			strictEqual( value3, 6, "result of filter ok" );
			
			$.Deferred().reject().pipe(function() {
				ok( false, "pipe should not be called on reject" );
			});
			
			$.Deferred().resolve().pipe( $.noop ).done(function( value ) {
				strictEqual( value, undefined, "pipe done callback can return undefined/null" );
			});
			
			confirmExpected();
		}

		
		[Test(order=4, description="$.Deferred - filtering (fail)")]
		public function test_jQueryDeferred_filterWithReject():void 
		{
			expect(4);
			
			var defer = $.Deferred(),
				piped = defer.pipe( null, function(a, b ) {
					return a * b;
				} ),
				value1,
				value2,
				value3;
			
			piped.fail(function(c ) {
				value3 = c;
			});
			
			defer.fail( function( a, b ) {
				value1 = a;
				value2 = b;
			});
			
			defer.reject( 2, 3 );		
			
			strictEqual( 2, value1, "first reject value ok" );
			strictEqual( 3, value2, "second reject value ok" );
			strictEqual( 6, value3, "result of filter ok" );
			
			$.Deferred().done().pipe( null, function() {
				ok( false, "pipe should not be called on resolve" );
			} );
			
			$.Deferred().reject().pipe( null, $.noop ).fail(function( value ) {
				strictEqual( value, undefined, "pipe fail callback can return undefined/null" );
			});
			
			confirmExpected();
		}		
		
		[Test(order=5, description="$.Deferred - filtering (progress)")]
		public function test_jQueryDeferred_filterWithProgress():void 
		{
			expect(3);
			
			var defer = $.Deferred(),
				piped = defer.pipe( null, null, function( a,b ) { 		
					return a*b;
				}),
				value1,
				value2,
				value3;
			
			piped.progress(function( c) {
				value3 = c;
			});
			
			defer.progress(function( a,b) {
				value1 = a;
				value2 = b;
			});
			
			defer.notify( 2, 3 );
			
			strictEqual( value1, 2, "first progress value ok" );
			strictEqual( value2, 3, "second progress value ok" );
			strictEqual( value3, 6, "result of filter ok" );
			
			
			confirmExpected();
		}		
		
		[Test(order=6, description="$.Deferred.pipe - deferred (done)")]
		public function test_jQueryDeferred_pipeWithDone():void 
		{
			expect(3);
			
			var defer = $.Deferred(),
				piped = defer.pipe(function( a, b ) {
					return $.Deferred(function( defer ) {
						defer.reject( a * b );
					});
				}),
				value1,
				value2,
				value3;
			
			piped.fail(function( c ) {
				value3 = c;
			});
			
			defer.done(function( a,b ) {
				value1 = a;
				value2 = b;
			});
			
			defer.resolve( 2, 3 );
			
			strictEqual( value1, 2, "first resolve value ok" );
			strictEqual( value2, 3, "second resolve value ok" );
			strictEqual( value3, 6, "result of filter ok" );
			
			
			confirmExpected();
		}		
		
		
		[Test(order=7, description="$.Deferred.pipe - deferred (fail)")]
		public function test_jQueryDeferred_pipeWithFail():void 
		{
			expect(3);
			
			var defer = $.Deferred(),
				piped = defer.pipe(null, function( a, b ) {
					return $.Deferred(function( defer ) {
						defer.resolve( a*b );
					});
				}),
				value1,
				value2,
				value3;
			
			piped.done(function( c ) {
				value3 = c;
			});
			
			defer.fail(function( a,b ) {
				value1 = a;
				value2 = b;
			});
			
			defer.reject( 2, 3 );
			
			strictEqual( value1, 2, "first resolve value ok" );
			strictEqual( value2, 3, "second resolve value ok" );
			strictEqual( value3, 6, "result of filter ok" );
			
			
			confirmExpected();
		}		
		
		
		
		[Test(order=8, description="$.Deferred.pipe - deferred (progress)")]
		public function test_jQueryDeferred_pipeWithProgress():void 
		{
			expect(3);
			
			var defer = $.Deferred(),
				piped = defer.pipe(null, null, function( a, b ) {
					return $.Deferred(function( defer ) {
						defer.resolve( a*b );
					});
				}),
				value1,
				value2,
				value3;
			
			piped.done(function( c ) {
				value3 = c;
			});
			
			defer.progress( function( a,b ) {
				value1 = a;
				value2 = b;
			});
			
			defer.notify( 2, 3 );
			
			strictEqual( value1, 2, "first resolve value ok" );
			strictEqual( value2, 3, "second resolve value ok" );
			strictEqual( value3, 6, "result of filter ok" );
			
			
			confirmExpected();
		}		
		
		
		[Test(order=9, description="jQuery.when")]
		public function test_jQuery_when():void 
		{
			expect( 21 );
			
			// Some other objects
			$.each( {
				"an empty string"			: "",
				"a non-empty string"		: "some string",
				"zero"						: 0,	
				"a number other than zero"	: 1,
				"true"						: true,
				"false"						: false,
				"null"						: null,
				//"undefined"				: undefined,
				"a plain object"			: {}
				
			} , function( message , value ) {
				
				var obj = $.when( value )
				           .done(function( resolveValue ) {
								strictEqual( resolveValue , value , "Test the promise was resolved with " + message );
						   });
				ok( (obj as Promise) != null , "Test " + message + " triggers the creation of a new Promise" );
				
			} );
			
			
			var obj =  $.when()
						.done( function( resolveValue ) {
							strictEqual( resolveValue , undefined , "Test the promise was resolved with no parameter" );
						});
			ok( (obj as Promise) != null, "Test calling when with no parameter triggers the creation of a new Promise" );
			
			var cache, i;
			
			for( i = 1 ; i < 4 ; i++ ) {
				$.when( cache || $.Deferred( function(dfd) {
					dfd.resolve( i );
				}) ).done(function( value ) {
					strictEqual( value , 1 , "Function executed" + ( i > 1 ? " only once" : "" ) );
					cache = value;
				});
			}
			
			confirmExpected();
		}	
		
		[Ignore]
		[Test(order=10, description="jQuery.when - joined")]
		public function test_jQuery_whenJoined():void 
		{
			expect(53);
			
			var deferreds = {
					value		 : 1,
					success		 : $.Deferred().resolve( 1 ),
					error		 : $.Deferred().reject( 0 ),
					futureSuccess: $.Deferred().notify( true ),
					futureError	 : $.Deferred().notify( true ),
					notify		 : $.Deferred().notify( true )
				},
				willSucceed = {
					value		 : true,
					success		 : true,
					futureSuccess: true
				},
				willError = {
					error		 : true,
					futureError	 : true
				},
				willNotify = {
					futureSuccess: true,
					futureError	 : true,
					notify		 : true
				};
			
			$.each( deferreds, function( id1, defer1 ) {
				$.each( deferreds, function( id2, defer2 ) {
					
					var shouldResolve  = willSucceed[ id1 ]  && willSucceed[ id2 ],
						shouldError    = willError  [ id1 ]  || willError  [ id2 ],
						shouldNotify   = willNotify [ id1 ]  || willNotify [ id2 ],
						expectedNotify = shouldNotify  && [ willNotify[ id1 ], willNotify[ id2 ] ],
						expected       = shouldResolve ? [ 1, 1 ] : [ 0, undefined ],
						code           = id1 + "/" + id2;
					
					var promise =  $.when( defer1, defer2 )
									.done(function( d ) {
										if ( shouldResolve ) {
											deepEqual( d, expected, code + " => resolve" );
										} else {
											ok( false , code + " => resolve" );
										}
									})
									.fail(function( d ) {
										if ( shouldError ) {
											deepEqual( d, expected, code + " => reject" );
										} else {
											ok( false , code + " => reject" );
										}
									})
									.progress(function progress( d ) {
										deepEqual( d, expectedNotify, code + " => progress" );
									});
				});
			});
			
			deferreds.futureSuccess.resolve( 1 );
			deferreds.futureError.reject( 0 );
			
			confirmExpected();
		}
		
		
		// *****************************************************************************
		// Protected Methods
		// *****************************************************************************
		protected function expect(val:uint):void {
			expectedChecks = val;
		}
		
		protected function confirmExpected():void {
			Assert.assertEquals("expected validations = "+ expectedChecks, expectedChecks, alwaysHitCount );
		}
		
		protected function ok(value:Boolean,message:String):void 	
		{   
			alwaysHitCount++; 	
			Assert.assertTrue(message,value); 	
		}
		
		protected function deepEqual(actual, expected, msg):void {
			var matches : Boolean = true;
			
			for (var key in actual) {
			 	matches &&= (expected.hasOwnProperty(key) && actual[key] == expected[key]);	
			}
			
			alwaysHitCount++; 
			Assert.assertTrue(msg, matches);
		}
		protected function strictEqual(state:*,value:*, message:String):void 	
		{   
			alwaysHitCount++;
			
			state = !(state is Array) 				? state 	:
					 (state as Array).length == 0 	? null		:
					 (state as Array).length == 1   ? state[0]	: state;
			
			Assert.assertStrictlyEquals( message, state, value); 	
		}
		protected function notStrictEqual(state:*,value:*, message:String):void 	
		{   
			alwaysHitCount++; 	
			Assert.assertFalse(message,state === value); 	
		}
		
		protected function initCounters():void {
			alwaysHitCount      = 0;
			alwaysReponse     	= null;
		}
		
		// *****************************************************************************
		// Private Properties 
		// *****************************************************************************
		
		private var $					:Object;
		
		private var alwaysHitCount      :int;
		private var alwaysReponse		:*;
		
		private var expectedChecks      :uint;
		
		
	}
}