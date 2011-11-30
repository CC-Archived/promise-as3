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
	
	import org.flexunit.Assert;
	import org.flexunit.async.Async;

	/**
	 * TestCase for all features of Deferred.as
	 *
	 */
	public class TestDeferred
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
			deferred = new Deferred();
			
			initCounters();
		}
		
		[After]
		public function tearDown():void
		{
			deferred = null;
		}
		
		// *****************************************************************************
		// Public Tests 
		// *****************************************************************************
		
		[Test(order=1.1, description="Confirm `new Deferred()` initializes properly & does not trigger handlers.")]
		public function testConstruction():void 
		{
			initCounters();
			
			checkDefaults( 
				new Deferred().then( onResultHandler, onErrorHandler, onProgressHandler, onCancelHandler ) 
			);
		}
		
		[Test(order=1.2, description="Confirm `new Deferred( function(dfd){} )` initializes properly & does not trigger handlers.")]
		public function testConstruction_parameterized():void 
		{
			initCounters();
			
			// Use preferred method of `parameterized` construction
			
			var dfd : Deferred = new Deferred( function(dfd) {
									Assert.assertEquals("dfd == this", this, dfd);
									
									checkDefaults( dfd.then( onResultHandler, 
															 onErrorHandler, 
															 onProgressHandler, 
															 onCancelHandler ) 
												 );
								});
				
			checkDefaults( dfd );
			
		}

		[Test(order=2.1, description="Test Deferred::resolve() works properly and only 1x.")]
		public function testResolve():void 
		{
			initCounters();
			
			// Use preferred method of `parameterized` construction
			
			var dfd = new Deferred( function(dfd) {
				checkDefaults( dfd );
			})
			.then( onResultHandler, onErrorHandler, onProgressHandler, onCancelHandler )
			.resolve( "Resolved" );
			
				checkResults(dfd, true, "Resolved", 1);		// Only the resolve information should have changed.
				checkRejects(dfd, false, null, 0);
				checkUpdates(dfd, false, null, 0);
				checkCancels(dfd, false, null, 0);
				
				Assert.assertFalse( "Resolved deferred has 'pending' == false",  dfd.pending );	
			
			dfd.resolve( "Resolved #2" );

				checkResults(dfd, true, "Resolved", 1);		// Should be same as before; since first resolve() locks all state
				checkRejects(dfd, false, null, 0);
				checkUpdates(dfd, false, null, 0);
				checkCancels(dfd, false, null, 0);
		}
		

		[Test(order=2.2, async, timeout="50", description="Test Deferred::resolve() works properly and only 1x.")]
		public function testResolve_asynch():void 
		{
			initCounters();
			
			// Use preferred method of `parameterized` construction
			
			var dfd = new Deferred( function(dfd) {
				checkDefaults( dfd.then( onResultHandler, onErrorHandler, onProgressHandler, onCancelHandler ) );
			});
					
			checkResults(dfd, false, null, 0);
			checkRejects(dfd, false, null, 0);
			checkUpdates(dfd, false, null, 0);
			checkCancels(dfd, false, null, 0);
			
			Assert.assertTrue( "Deferred is still 'pending' since async is running.",  dfd.pending );	
			
			Async.delayCall(this, function(){
				dfd.resolve( "Resolved Async" );
				
				checkResults(dfd, true, "Resolved Async", 1);		// Should be same as before; since first resolve() locks all state
				checkRejects(dfd, false, null, 0);
				checkUpdates(dfd, false, null, 0);
				checkCancels(dfd, false, null, 0);
			},30);		
		}
		

		
		
		[Test(order=3.1, description="Test Deferred::reject() invoked AFTER callbacks added.")]
		public function testReject_withCallbacks():void 
		{
			initCounters();
			
			// Use preferred method of `parameterized` construction, attach handlers, and then REJECT 
			
			var error = "Rejected for no reason.";
			var dfd = new Deferred( function(dfd) {
				checkDefaults( dfd );
				
				Assert.assertTrue( "Deferred 'pending' ===" + dfd.pending,  dfd.pending );	
			})
			.then( onResultHandler, onErrorHandler, onProgressHandler, onCancelHandler )
			.reject( error );

				
				checkResults(dfd, false, null, 0);
				checkRejects(dfd, true, error, 1);	// Only rejects should change
				checkUpdates(dfd, false, null, 0);
				checkCancels(dfd, false, null, 0);
			
				Assert.assertFalse( "Deferred 'pending' === false",  dfd.pending );
			
			dfd.reject( "Rejected #2" );
			
				
				checkResults(dfd, false, null, 0);
				checkRejects(dfd, true, error, 1);	// Should be same as before; since only allowed reject 1x
				checkUpdates(dfd, false, null, 0);
				checkCancels(dfd, false, null, 0);
				
				Assert.assertFalse( "Deferred 'pending' === false",  dfd.pending );

			dfd.resolve( "Resolve after rejection" );
			
				
				checkResults(dfd, false, null, 0);
				checkRejects(dfd, true, error, 1);	// Should be same as before; since the first rejection/cancel/resolve locks state
				checkUpdates(dfd, false, null, 0);
				checkCancels(dfd, false, null, 0);
				
				Assert.assertFalse( "Deferred 'pending' === false",  dfd.pending );

			dfd.cancel( "Cancel after rejection" );
			
				checkResults(dfd, false, null, 0);
				checkRejects(dfd, true, error, 1);	// Should be same as before; since the first rejection/cancel/resolve locks state
				checkUpdates(dfd, false, null, 0);
				checkCancels(dfd, false, null, 0);
				
				Assert.assertFalse( "Deferred 'pending' === false",  dfd.pending );
			
			dfd.update( "Update after rejection" );
			
				
				checkResults(dfd, false, null, 0);
				checkRejects(dfd, true, error, 1);	// Should be same as before; since the first rejection/cancel/resolvelocks state
				checkUpdates(dfd, false, null, 0);
				checkCancels(dfd, false, null, 0);
				
				Assert.assertFalse( "Deferred 'pending' === false",  dfd.pending );
		}
		
		[Test(order=3.2, description="Test Deferred::reject() invoked BEFORE callbacks added.")]
		public function testReject_beforeCallbacks():void 
		{
			// Now do the Rejection BEFORE the handlers are assigned; to see if handlers are called properly
			
			initCounters();
			
			var error = "Rejected for no reason #2";
			var dfd = new Deferred( function(dfd) {
				
				// Here the 1st onErrorHandler() is called
				dfd.reject( error )
				   .then( onResultHandler, onErrorHandler );
				
				Assert.assertFalse( "Deferred 'pending' === false",  dfd.pending );
			});
			
			// Here the 2nd onErrorHandler() is called
			dfd.then( onResultHandler, onErrorHandler, onProgressHandler, onCancelHandler );
			
				checkResults(dfd, false, null, 0);
				checkRejects(dfd, true, error, 2);	// Error counter should increment to 2 with new error response
				checkUpdates(dfd, false, null, 0);
				checkCancels(dfd, false, null, 0);
				
				Assert.assertFalse( "Deferred 'pending' === false",  dfd.pending );
			
			// If we add more handlers, only the new reject errorHandler is called
			// Here the 3rd onErrorHandler() is called
			
			dfd.then( onResultHandler, onErrorHandler );
			
				checkResults(dfd, false, null, 0);
				checkRejects(dfd, true, error, 3);	// Error counter should increment to 3
				checkUpdates(dfd, false, null, 0);
				checkCancels(dfd, false, null, 0);
				
				Assert.assertFalse( "Deferred 'pending' === false",  dfd.pending );
		}		

		[Test(order=4.1, description="Test Deferred::update() works properly but stops resolve.")]
		public function testUpdate_withResolve():void 
		{
			initCounters();
			
			// Use preferred method of `parameterized` construction and the REJECT
			
			var msg = "Update #1";
			var dfd = new Deferred( function(dfd) {
					checkDefaults( dfd );
					Assert.assertTrue( "Deferred 'pending' === true",  dfd.pending );
			})
			.then( onResultHandler, onErrorHandler, onProgressHandler, onCancelHandler )
			.update( msg );
			
				checkResults(dfd, false, null, 0);
				checkRejects(dfd, false, null, 0)
				checkUpdates(dfd, true,  msg, 1);	// Only update state has changed
				checkCancels(dfd, false, null, 0);
				
				Assert.assertTrue( "Deferred 'pending' === true",  dfd.pending );

			// Now attempt to update while still pending

			msg = "Update #2";
			dfd.update( msg );
			
				checkResults(dfd, false, null, 0);
				checkRejects(dfd, false, null, 0)
				checkUpdates(dfd, true,  msg, 2);	// Only update state has changed
				checkCancels(dfd, false, null, 0);
				
				Assert.assertTrue( "Deferred 'pending' === true",  dfd.pending );
			
			// Now attempt to update after a ::resolve()
				
			msg = "Update #3";
			dfd.resolve( "Locked" )
			   .update( msg );
				
				checkResults(dfd, true, "Locked", 1);
				checkRejects(dfd, false, null, 0)
				checkUpdates(dfd, true,  "Update #2", 2);	// update #3 should have been SKIPPED
				checkCancels(dfd, false, null, 0);
				
				Assert.assertFalse( "Deferred 'pending' === false",  dfd.pending );
		}

		[Test(order=4.2, description="Test Deferred::update() after cancel")]
		public function testUpdate_withCancel():void 
		{
			initCounters();
			
			// Now attempt to update after a ::cancel()
			
			var msg = "Update after ::cancel()";
			var dfd = new Deferred( function(dfd) {
						initCounters();
						checkDefaults( dfd );
						dfd.cancel("Cancelled");
						
						Assert.assertFalse( "Deferred 'pending' === false",  dfd.pending );
					})	
					.then( onResultHandler, onErrorHandler, onProgressHandler, onCancelHandler )
					.update( msg );
			
			checkResults(dfd, false, null, 0)
			checkRejects(dfd, false, null, 0);
			checkUpdates(dfd, false, null, 0);			// update should have been SKIPPED
			checkCancels(dfd, true, "Cancelled", 1);
			
			Assert.assertFalse( "Deferred 'pending' === false",  dfd.pending );
			
		}		

		[Test(order=4.3, description="Test Deferred::update() after reject()")]
		public function testUpdate_withReject():void 
		{
			initCounters();
			
			// Now attempt to update after a ::reject()
			
			var msg = "Update after ::reject()";
			var dfd = new Deferred( function(dfd) {
						initCounters();
						checkDefaults( dfd );
						dfd.reject("Rejected");
						
						Assert.assertFalse( "Deferred 'pending' === false",  dfd.pending );
					})	
					.then( onResultHandler, onErrorHandler, onProgressHandler, onCancelHandler )
					.update( msg );
			
			checkResults(dfd, false, null, 0)
			checkRejects(dfd, true, "Rejected", 1);
			checkUpdates(dfd, false, null, 0);			// update should have been SKIPPED
			checkCancels(dfd, false, null, 0);
			
			Assert.assertFalse( "Deferred 'pending' === false",  dfd.pending );
		}
		
		[Test(order=5.1, description="Confirm Deferred::cancel() works properly and only 1x.")]
		public function testCancel():void 
		{
			initCounters();
			
			// Use preferred method of `parameterized` construction and the REJECT
			
			var msg = "Cancelled for no reason.";
			var dfd = new Deferred( function(dfd) {
				checkDefaults( dfd );
			})
			.then( onResultHandler, onErrorHandler, onProgressHandler, onCancelHandler )
			.cancel( msg );
			
				checkResults(dfd, false, null, 0);
				checkRejects(dfd, false, null, 0);
				checkUpdates(dfd, false, null, 0);
				checkCancels(dfd, true,  msg, 1);	// Only cancel should change
				
				Assert.assertFalse( "Deferred 'pending' === false",  dfd.pending );
				
			
			dfd.cancel( "Cancelled #2" );
			
				checkResults(dfd, false, null, 0);
				checkRejects(dfd, false, null, 0);
				checkUpdates(dfd, false, null, 0);
				checkCancels(dfd, true,  msg, 1);	// Should be same as before; since the can only cancel 1x
				
				Assert.assertFalse( "Deferred 'pending' === false",  dfd.pending );
			
			dfd.resolve( "Resolve after cancel" );
			
				checkResults(dfd, false, null, 0);
				checkRejects(dfd, false, null, 0);
				checkUpdates(dfd, false, null, 0);
				checkCancels(dfd, true,  msg, 1);	// Should be same as before; since the first rejection/cancel/resolve locks state
				
				Assert.assertFalse( "Deferred 'pending' === false",  dfd.pending );
			
			dfd.update( "Update after cancel" );
				
				checkResults(dfd, false, null, 0);
				checkRejects(dfd, false, null, 0);
				checkUpdates(dfd, false, null, 0);
				checkCancels(dfd, true,  msg, 1);	// Should be same as before; since the first rejection/cancel/resolve locks state
				
				Assert.assertFalse( "Deferred 'pending' === false",  dfd.pending );
		}		
		
		
		[Test(order=5.2, description="Confirm Deferred::cancel() invoked before callbacks added")]
		public function testCancel_beforeCallbacks():void 
		{
			// Now do the Cancel BEFORE the handlers are assigned; to see if handlers are called properly
			
			initCounters();
			
			var msg = 	"Cancel for no reason #2";
			var dfd = 	new Deferred( function(dfd) {
							
							// Here the 1st onCancelHandler() is called
							dfd.cancel( msg )
								.then( onResultHandler, onErrorHandler, null, onCancelHandler );
							
							Assert.assertFalse( "Deferred 'pending' === false",  dfd.pending );
						});
			
			// Here the 2nd onCancelHandler() is called
			
			dfd.then( onResultHandler, onErrorHandler, onProgressHandler, onCancelHandler );
			
			
			checkResults(dfd, false, null, 0);
			checkRejects(dfd, false, null, 0);
			checkUpdates(dfd, false, null, 0);
			checkCancels(dfd, true,  msg, 2);	// Should be 2 since dfd.then(..., onCancelHandler) was called
			
			Assert.assertFalse( "Deferred 'pending' === false",  dfd.pending );
			
			// If we add more handlers, only the new reject errorHandler is called
			// Here the 3rd onCancelHandler() is called
			
			dfd.then( onResultHandler, onErrorHandler, null, onCancelHandler );
			
			checkResults(dfd, false, null, 0);
			checkRejects(dfd, false, null, 0);
			checkUpdates(dfd, false, null, 0);
			checkCancels(dfd, true,  msg, 3);	// Should be 3 since dfd.then(..., onCancelHandler) was called
			
			Assert.assertFalse( "Deferred 'pending' === false",  dfd.pending );
			
			dfd.then( onResultHandler, onErrorHandler, null, null );
			
			checkResults(dfd, false, null, 0);
			checkRejects(dfd, false, null, 0);
			checkUpdates(dfd, false, null, 0);
			checkCancels(dfd, true,  msg, 3);	// Should be same 3 since dfd.then() did not include a cancelHandler
			
			Assert.assertFalse( "Deferred 'pending' === false",  dfd.pending );
		}			
		
		[Test(order=6.1, description="Test Deferred::always() works properly after cancel()")]
		public function testAlways_withCancel():void 
		{
			var msg : String; 
			var dfd : Deferred; 
			
			// (1) Confirm always works with then() and cancel()
			
			msg = 	"Always responded";
			dfd = 	new Deferred( function(dfd) {
						initCounters();
						checkDefaults( dfd ).always( onAlwaysHandler )
					})
					.then( onResultHandler, onErrorHandler, onProgressHandler, onCancelHandler )
					.cancel( msg );
			
				checkResults(dfd, false, null, 0);
				checkRejects(dfd, false, null, 0);
				checkUpdates(dfd, false, null, 0);
				checkCancels(dfd, true,  msg,  1);	// Only cancel should change
				
				checkAlways(dfd,true,msg,2);		// then() and cancel() trigger always() 2x
				
				Assert.assertFalse( "Deferred 'pending' === false",  dfd.pending );
				
			dfd.update("nothing should happen");
			
				checkResults(dfd, false, null, 0);
				checkRejects(dfd, false, null, 0);
				checkUpdates(dfd, false, null, 0);
				checkCancels(dfd, true,  msg,  1);	// Values are locked from line 404
				
				checkAlways(dfd,true,msg,2);		// Values are locked from line 404
				
				Assert.assertFalse( "Deferred 'pending' === false",  dfd.pending );
				
			dfd.resolve("nothing should happen");
			
				checkResults(dfd, false, null, 0);
				checkRejects(dfd, false, null, 0);
				checkUpdates(dfd, false, null, 0);
				checkCancels(dfd, true,  msg,  1);	// Values are locked from line 404
				
				checkAlways( dfd, true,  msg,  2);		// Values are locked from line 404
				
				Assert.assertFalse( "Deferred 'pending' === false",  dfd.pending );
				
			dfd.reject("nothing should happen");
				
				checkResults(dfd, false, null, 0);
				checkRejects(dfd, false, null, 0);
				checkUpdates(dfd, false, null, 0);
				checkCancels(dfd, true,  msg,  1);	// Values are locked from line 404
				
				checkAlways( dfd, true,  msg,  2);		// Values are locked from line 404
				
				Assert.assertFalse( "Deferred 'pending' === false",  dfd.pending );
			
			dfd.cancel("nothing should happen");
				
				checkResults(dfd, false, null, 0);
				checkRejects(dfd, false, null, 0);
				checkUpdates(dfd, false, null, 0);
				checkCancels(dfd, true,  msg,  1);	// Values are locked from line 404
				
				checkAlways( dfd, true,  msg,  2);		// Values are locked from line 404
			
				Assert.assertFalse( "Deferred 'pending' === false",  dfd.pending );
		}
		
		[Test(order=6.2, description="Test Deferred::always() works properly after cancel()")]
		public function testAlways_withCancel2():void 
		{
			var msg : String; 
			var dfd : Deferred; 
			
			// (3) Confirm that always()s works with update() and cancel()
			
			msg = 	"Cancelled";
			dfd = 	new Deferred( function(dfd) {
						initCounters();
						checkDefaults( dfd );
					})
					.then( onResultHandler, onErrorHandler, null, onCancelHandler)
					.always( onAlwaysHandler )
					.update( "update 1" )
					.update( "update 2" )
					.cancel(msg);
			
			checkResults(dfd, false,  null, 		0);
			checkRejects(dfd, false,  null, 		0);
			checkUpdates(dfd, false,  "update 2",	0);	// since progressHandler == null
			checkCancels(dfd, true,   msg, 			1);	// Only cancel should change
			
			checkAlways(dfd,  true,  msg,			2);	// onCancelHandler() and cancel() => 2x
			
			Assert.assertFalse( "Deferred 'pending' === false",  dfd.pending );
		}
		

		[Test(order=6.3, description="Test Deferred::always() works properly after resolve()")]
		public function testAlways_withResolve():void 
		{
			var msg : String; 
			var dfd : Deferred; 
			
			// 2) Confirm that always()s works with update() and resolve()
			
			msg = 	"Resolved";
			dfd = 	new Deferred( function(dfd) {
						initCounters();
						checkDefaults( dfd ).always( onAlwaysHandler );
					})
					.then( onResultHandler, onErrorHandler, onProgressHandler)
					.always( onAlwaysHandler )
					.update( msg )
					.update( msg )
					.resolve(msg);
			
			checkResults(dfd, true,  msg, 1);
			checkRejects(dfd, false, null, 		0);
			checkUpdates(dfd, true,  msg, 		2);
			checkCancels(dfd, false, null, 		0);	// Only cancel should change
			
			checkAlways(dfd,  true,  msg,		3);	// onProgressHandler() and resolve() triggers always() 3x
			
			Assert.assertFalse( "Deferred 'pending' === false",  dfd.pending );
			
			// (3) Confirm that always()s works with update() and cancel()
			
			msg = 	"Cancelled";
			dfd = 	new Deferred( function(dfd) {
						initCounters();
						checkDefaults( dfd );
					})
					.then( onResultHandler, onErrorHandler, null, onCancelHandler)
					.always( onAlwaysHandler )
					.update( "update 1" )
					.update( "update 2" )
					.cancel(msg);
			
			checkResults(dfd, false,  null, 		0);
			checkRejects(dfd, false,  null, 		0);
			checkUpdates(dfd, false,  "update 2",	0);	// since progressHandler == null
			checkCancels(dfd, true,   msg, 			1);	// Only cancel should change
			
			checkAlways(dfd,  true,  msg,			2);	// onCancelHandler() and cancel() => 2x
			
			Assert.assertFalse( "Deferred 'pending' === false",  dfd.pending );
		}
		
		
		// *****************************************************************************
		// Protected Methods
		// *****************************************************************************
		
		protected function onResultHandler(val:*):void	{	
			resultHitCount++;	alwaysHitCount++; 
		}
		protected function onErrorHandler(val:*):void	{	errorHitCount++;	alwaysHitCount++; }
		protected function onProgressHandler(val:*):void{	progressHitCount++;						}
		protected function onCancelHandler(val:*):void	{	cancelHitCount++;	alwaysHitCount++; }
		
		protected function onAlwaysHandler(val:*):void	{	alwaysHitCount++; alwaysReponse = val;	}
		
		// *****************************************************************************
		// Private Methods 
		// *****************************************************************************
		
		private function initCounters(rVal:int=0, pVal:int=0, eVal:int=0, cVal:int=0):void {
			resultHitCount 		= rVal;		
			progressHitCount	= pVal;
			errorHitCount		= eVal;
			cancelHitCount		= cVal;
			
			alwaysHitCount      = 0;
			alwaysReponse     	= null;
		}
		
		private function checkDefaults(dfd:Deferred):Deferred {
			
			checkResults(dfd, false, null, 0);
			checkRejects(dfd, false, null, 0);
			checkCancels(dfd, false, null, 0);
			checkUpdates(dfd, false, null, 0);
			checkAlways(dfd, false, null, 0);
			
			Assert.assertTrue( "Pending deferred has 'pending' == true", 	 dfd.pending );
			
			return dfd;
		}
		
		private function checkResults(dfd:Object, state:Boolean, response:*=null,count:int=0):void {
				
			Assert.assertEquals( "Deferred has `result` == " + response, 	response, dfd.result 	 	);
			Assert.assertEquals( "Deferred has 'succeeded' ==" + state, 	state, 	  dfd.resolved 	);
			Assert.assertEquals( "Deferred has resultHitCount ==" +count,  	count, 	  resultHitCount  	);
		}
		
		private function checkRejects(dfd:Object, state:Boolean,response:*=null,count:int=0):void {
			
			Assert.assertEquals( "Deferred has `error` == " + response, 	response, dfd.error 	);
			Assert.assertEquals( "Deferred has 'failed' ==" + state, 		state   , dfd.rejected	);
			Assert.assertEquals( "Deferred has errorHitCount ==" +count,  	count   , errorHitCount );
		}
		
		private function checkCancels(dfd:Object, state:Boolean,response:*=null,count:int=0):void {
			
			Assert.assertEquals( "Deferred has `reason` == " + response, 	response, 	dfd.reason 	 	);
			Assert.assertEquals( "Deferred has 'cancelled' ==" + state, 	state, 		dfd.cancelled 	);
			Assert.assertEquals( "Deferred has cancelHitCount ==" +count,  	count, 		cancelHitCount  );
		}
		
		private function checkUpdates(dfd:Object, state:Boolean,response:*=null,count:int=0):void {
			
			Assert.assertEquals( "Deferred has `progress` == " + response, 	response, dfd.status 	 	);
			Assert.assertEquals( "Deferred has progressHitCount ==" +count, count   , progressHitCount  );
		}
		
		
		private function checkAlways(dfd:Object, state:Boolean,response:*=null,count:int=0):void {
			
			Assert.assertEquals( "Deferred has `alwaysReponse` == "+alwaysReponse, 	response, alwaysReponse 	 	);
			Assert.assertEquals( "Deferred has alwaysHitCount ==" +count, 			count   , alwaysHitCount  );
		}

		// *****************************************************************************
		// Private Properties 
		// *****************************************************************************
		
		private var deferred			:Deferred;

		private var resultHitCount		:int;
		private var progressHitCount	:int;
		private var errorHitCount		:int;
		private var cancelHitCount		:int;
		
		private var alwaysHitCount      :int;
		private var alwaysReponse		:*;
		
		
	}
}