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
	import com.codecatalyst.promise.util.jQuery;
	
	import flexunit.framework.TestCase;
	
	import org.flexunit.Assert;

	/**
	 * Imported the QUnit javascript tests for jQuery Callbacks.
	 * 
	 * @see https://github.com/jquery/jquery/blob/master/test/unit/callbacks.js
	 * 
	 * Possible flags:
	 *
	 *	     once:			will ensure the callback list can only be fired once (like a Deferred)
	 *       
	 *	     memory:		will keep track of previous values and will call any callback added
	 *	     				after the list has been fired right away with the latest "memorized"
	 *	     				values (like a Deferred)
	 *       
	 *	     unique:		will ensure a callback can only be added once (no duplicate in the list)
	 *       
	 *	     stopOnFalse:	interrupt callings when a callback returns false
	 *
	 */
	public class TestCallbacks
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
			jQuery = com.codecatalyst.promise.util.jQuery();
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
		// Port Issues:
		//   
		//    1) 'once memory' test below does not validate. Unknown reason.
		//
		// *****************************************************************************
		
		[Test(order=1, description="Port of jQuery QUnit tests: callbacks.js")]
		public function test_jQueryCallbacks():void 
		{
			var output				:String;
			var addToOutput         :Function = function(string) {
													return function() { 
														output += string 
													};
												};
			
			var outputA             :Function = addToOutput( "A" ),
				outputB             :Function = addToOutput( "B" ),
				outputC             :Function = addToOutput( "C" ),
				
				tests = {
							"": 				  "XABC X XABCABCC X XBB X XABA X",
							"once": 			  "XABC X X X X X XABA X",
							"memory": 			  "XABC XABC XABCABCCC XA XBB XB XABA XC",
							"unique": 			  "XABC X XABCA X XBB X XAB X",
							"stopOnFalse": 		  "XABC X XABCABCC X XBB X XA X",
							"once memory": 		  "XABC XABC X XA X XA XABA XC",		
							"once unique": 		  "XABC X X X X X XAB X",
							"once stopOnFalse":   "XABC X X X X X XA X",
							"memory unique": 	  "XABC XA XABCA XA XBB XB XAB XC",
							"memory stopOnFalse": "XABC XABC XABCABCCC XA XBB XB XA X",
							"unique stopOnFalse": "XABC X XABCA X XBB X XA X"
						},
				filters = {
							"no filter": undefined,
							"filter"   : function( fn ) {
								return function() {
									return fn.apply( this, arguments );
								};
							}
						};

			

			jQuery.each( tests, function( flags, resultString ) {
				
				jQuery.each( filters, function( filterLabel, filter ) {

						expect( 17 );
						
						var cblist,
							results = resultString.split( /\s+/ );
						
						// Basic binding and firing
						output = "X";
						cblist = jQuery.Callbacks( flags );
						cblist.add(function( str ) {
							output += str;
						});
						cblist.fire( "A" );
						strictEqual( output, "XA", "Basic binding and firing" );
						output = "X";
						cblist.disable();
						cblist.add(function( str ) {
							output += str;
						});
						strictEqual( output, "X", "Adding a callback after disabling" );
						cblist.fire( "A" );
						strictEqual( output, "X", "Firing after disabling" );
						
						// Basic binding and firing (context, arguments)
						output = "X";
						cblist = jQuery.Callbacks( flags );
						cblist.add(function() {
							output += arguments.join( "" );
						});
						cblist.fire( "A", "B" );
						strictEqual( output, "XAB", "Basic binding and firing (arguments)" );
						
						// fireWith with no arguments
						output = "";
						cblist = jQuery.Callbacks( flags );
						cblist.add(function() {
							strictEqual( arguments.length, 0, "fireWith with no arguments (no arguments)" );
						});
						cblist.fire();
						
						// Basic binding, removing and firing
						output = "X";
						cblist = jQuery.Callbacks( flags );
						cblist.add( outputA, outputB, outputC );
						cblist.remove( outputB, outputC );
						cblist.fire();
						strictEqual( output, "XA", "Basic binding, removing and firing" );
						
						// Empty
						output = "X";
						cblist = jQuery.Callbacks( flags );
						cblist.add( outputA );
						cblist.add( outputB );
						cblist.add( outputC );
						cblist.empty();
						cblist.fire();
						strictEqual( output, "X", "Empty" );
						
						// Locking
						output = "X";
						cblist = jQuery.Callbacks( flags );
						cblist.add( function( str ) {
							output += str;
						});
						cblist.lock();
						cblist.add( function( str ) {
							output += str;
						});
						cblist.fire( "A" );
						cblist.add( function( str ) {
							output += str;
						});
						strictEqual( output, "X", "Lock early" );
						
						// Ordering
						output = "X";
						cblist = jQuery.Callbacks( flags );
						cblist.add( function() {
							cblist.add( outputC );
							outputA();
						}, outputB );
						cblist.fire();
						strictEqual( output, results.shift(), "Proper ordering" );
						
						// Add and fire again
						output = "X";
						cblist.add( function() {
							cblist.add( outputC );
							outputA();
						}, outputB );
						strictEqual( output, results.shift(), "Add after fire" );
						
						output = "X";
						cblist.fire();
						strictEqual( output, results.shift(), "Fire again" );
						
						// Multiple fire
						output = "X";
						cblist = jQuery.Callbacks( flags );
						cblist.add( function( str ) {
							output += str;
						} );
						cblist.fire( "A" );
						strictEqual( output, "XA", "Multiple fire (first fire)" );
						output = "X";
						cblist.add( function( str ) {
							output += str;
						} );
						strictEqual( output, results.shift(), "Multiple fire (first new callback)" );
						output = "X";
						cblist.fire( "B" );
						strictEqual( output, results.shift(), "Multiple fire (second fire)" );
						output = "X";
						cblist.add( function( str ) {
							output += str;
						} );
						strictEqual( output, results.shift(), "Multiple fire (second new callback)" );
						
						// Return false
						output = "X";
						cblist = jQuery.Callbacks( flags );
						cblist.add( outputA, function() { return false; }, outputB );
						cblist.add( outputA );
						cblist.fire();
						strictEqual( output, results.shift(), "Callback returning false" );
						
						// Add another callback (to control lists with memory do not fire anymore)
						output = "X";
						cblist.add( outputC );
						strictEqual( output, results.shift(), "Adding a callback after one returned false" );
						
					confirmExpected();
				});
			});			

			
		}
				
	
		// *****************************************************************************
		// Simulation of QUnit methods
		// *****************************************************************************
		
		protected function expect(val:uint):void {
			expectedHits = val;
		}
		
		protected function confirmExpected():void {
			Assert.assertEquals("expected validations = "+ expectedHits, expectedHits, generatedHits );
			generatedHits = 0;
		}
		
		protected function ok(value:Boolean,message:String):void 	
		{   
			generatedHits++; 	
			Assert.assertTrue(message,value); 	
		}
		
		protected function deepEqual(actual, expected, msg):void {
			var matches : Boolean = true;
			
			for (var key in actual) {
			 	matches &&= (expected.hasOwnProperty(key) && actual[key] == expected[key]);	
			}
			
			generatedHits++; 
			Assert.assertTrue(msg, matches);
		}
		
		protected function strictEqual(state:*,value:*, message:String):void 	
		{   
			generatedHits++;
			
			state = !(state is Array) 				? state 	:
					 (state as Array).length == 0 	? null		:
					 (state as Array).length == 1   ? state[0]	: state;
			
			Assert.assertStrictlyEquals( message, state, value); 	
		}
		
		protected function notStrictEqual(state:*,value:*, message:String):void 	
		{   
			generatedHits++; 	
			Assert.assertFalse(message,state === value); 	
		}
		
		// *****************************************************************************
		// Private Properties 
		// *****************************************************************************
		
		private var jQuery		  :Object;
		
		private var generatedHits :int;
		private var expectedHits  :uint;
		
		
	}
}