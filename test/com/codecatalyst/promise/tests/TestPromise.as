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
	
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.core.mx_internal;
	import mx.rpc.AsyncToken;
	import mx.rpc.Fault;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import org.flexunit.Assert;
	import org.flexunit.async.Async;

	/**
	 * TestCase for all features of Deferred.as
	 *
	 */
	public class TestPromise
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
		
		[Test(order=1.1, description="Confirm `new Deferred()` initializes read-only promise.")]
		public function testConstruction():void 
		{
			initCounters();
			
			var dfd 	= new Deferred();
			var promise	= dfd.promise;
			
			Assert.assertTrue( "dfd != promise", 		 dfd         != promise );
			Assert.assertTrue( "dfd.promise == promise", dfd.promise == promise );	// Only 1 instance created per Deferred
			
			checkDefaults( 
				promise.then( onResultHandler, 
					 		  onErrorHandler, 
							  onProgressHandler, 
							  onCancelHandler )
			);
		}
		
		[Test(order=1.2, description="Confirm `new Deferred( function(dfd){} )` initializes read-only promise.")]
		public function testConstruction_parameterized():void 
		{
			initCounters();
			
			// Use preferred method of `parameterized` construction
			
			checkDefaults( new Deferred( function(dfd:Deferred) {
				
				var promise : Promise = dfd.promise;
				
				// Notice SCOPE change within the constructor function handler
				
				Assert.assertEquals("dfd == this", 		this, dfd);
				Assert.assertFalse( "dfd != promise", 	dfd == promise);
				
				checkDefaults( 
					promise.then( onResultHandler, 
								  onErrorHandler, 
								  onProgressHandler, 
								  onCancelHandler ) 
							 );
			}) );
			
		}

		
		[Test(order=2.1, description="Test Promise::resolved().")]
		public function testResolve():void 
		{
			initCounters();
			
			// Use preferred method of `parameterized` construction
			
			var dfd     = new Deferred();
			var promise = dfd.promise;
			
				checkDefaults( promise );
				Assert.assertFalse( "Promise has not resolved.", 	 promise.resolved);
			
			dfd.resolve( "Resolved" );
			promise.then( onResultHandler );
			
			checkResults(promise, true, "Resolved", 1);		// Only the resolve information should have changed.
			checkRejects(promise, false, null, 0);
			checkUpdates(promise, false, null, 0);
			checkCancels(promise, false, null, 0);
			
			Assert.assertTrue( "Promise has been resolved.",  promise.resolved );	
		}


		[Test(order=3.1, description="Test Promise after reject() invoked.")]
		public function testReject():void 
		{
			initCounters();
			
			// Use preferred method of `parameterized` construction, attach handlers, and then REJECT 
			
			var error   = "Rejected for no reason.";
			var dfd     = new Deferred();
			var promise = dfd.promise
							 .then( onResultHandler, onErrorHandler, onProgressHandler, onCancelHandler );
			
			 	dfd.reject( error );
			
			 checkResults(promise, false, null, 0);
			 checkRejects(promise, true, error, 1);		// Only the resolve information should have changed.
			 checkUpdates(promise, false, null, 0);
			 checkCancels(promise, false, null, 0);
			 
			 Assert.assertFalse( "Promise has NOT been resolved.",    	promise.resolved );
			 Assert.assertTrue( "Promise has been failed/rejected.",  	promise.rejected );
		}		
		
		
		[Test(order=4.1, description="Test Promise and Deferred updates() works properly but stops after resolve.")]
		public function testUpdate_withResolve():void 
		{
			initCounters();
			
			// Use preferred method of `parameterized` construction and the REJECT
			
			var msg = "Update #1";
			var dfd     = new Deferred();
			var promise = dfd.promise
							 .then( onResultHandler, onErrorHandler, onProgressHandler, onCancelHandler );
			
				dfd.update( msg );
			
			checkResults(promise, false, null, 0);
			checkRejects(promise, false, null, 0);
			checkUpdates(promise, true,  msg, 1);	// Only update state has changed
			checkCancels(promise, false, null, 0);
			
			Assert.assertFalse( "Promise has NOT been resolved.",  promise.resolved );
			Assert.assertFalse( "Promise has NOT failed.",  		promise.rejected );
			Assert.assertFalse( "Promise has NOT cancelled.",  		promise.cancelled );

		}
		
		[Test(order=4.2, description="Test Promise and update() after cancel")]
		public function testUpdate_withCancel():void 
		{
			initCounters();
			
			// Now attempt to update after a ::cancel()
			
			var msg     = "Update after ::cancel()";
			var promise = new Deferred( function(dfd) {
				
				checkDefaults( dfd);
				dfd.cancel("Cancelled 4.2");
				
				Assert.assertTrue( "Deferred has cancelled.",  !dfd.pending );
				
			}).notify( msg )
			  .promise
			  .then( onResultHandler, onErrorHandler, onProgressHandler, onCancelHandler );
			
			checkResults(promise, false, null, 0)
			checkRejects(promise, false, null, 0);
			checkUpdates(promise, false, null, 0);			// update should have been SKIPPED
			checkCancels(promise, true, "Cancelled 4.2", 1);
			
			Assert.assertFalse( "Promise has not resolved",  promise.resolved);
			Assert.assertFalse( "Promise has not rejected",  promise.rejected);
			Assert.assertFalse( "Promise is not pending",promise.pending);
			
			Assert.assertTrue( "Promise has cancelled",  promise.cancelled);
		}		
		
		[Test(order=4.3, description="Test Promise and update() after reject")]
		public function testUpdate_withReject():void 
		{
			initCounters();
			
			// Now attempt to update after a ::cancel()
			
			var msg     = "Update after ::reject()";
			var promise = new Deferred( function(dfd) {
				
				checkDefaults( dfd);
				dfd.reject("Rejected 4.3");
				
				Assert.assertTrue( "Deferred has rejected.",  dfd.rejected);
				
			}).notify( msg )
			  .promise
			  .then( onResultHandler, onErrorHandler, onProgressHandler, onCancelHandler );
			
			checkResults(promise, false, null, 0)
			checkRejects(promise, true, "Rejected 4.3", 1);
			checkUpdates(promise, false, null, 0);			// update should have been SKIPPED
			checkCancels(promise, false, null, 0);
			
			Assert.assertFalse( "Promise has not resolved", promise.resolved);
			Assert.assertFalse( "Promise has not cancelled",promise.cancelled);
			
			Assert.assertTrue( "Promise is NOT pending",  	!promise.pending);
			Assert.assertTrue( "Promise is rejected",  		promise.rejected);
		}		

		
		[Test(order=5.1, description="Confirm Promise with Deferred::cancel().")]
		public function testCancel():void 
		{
			initCounters();
			
			// Use preferred method of `parameterized` construction and the REJECT
			
			var msg     = 	"Cancelled 5.1";
			var promise = 	new Deferred( function(dfd) {
								checkDefaults( dfd );
							})
							.then( onResultHandler, onErrorHandler, onProgressHandler, onCancelHandler )
							.cancel( msg )
							.promise
							.then( onResultHandler, onErrorHandler, onProgressHandler, onCancelHandler );
			
			checkResults(promise, false, null, 0)
			checkRejects(promise, false, null, 0);
			checkUpdates(promise, false, null, 0);			// update should have been SKIPPED
			checkCancels(promise, true, msg,   2);
			
			Assert.assertFalse( "Promise has not resolved", promise.resolved);
			Assert.assertFalse( "Promise has not rejected", promise.rejected);
			
			Assert.assertTrue( "Promise is NOT pending",  	!promise.pending);
			Assert.assertTrue( "Promise is cancelled",		promise.cancelled);

		}		

		
		[Test(order=6.1, description="Test Promise::always() works properly after cancel()")]
		public function testAlways_withCancel():void 
		{
			var msg 	: String,
			    dfd 	: Deferred,
				promise	: Promise;
			
			// (1) Confirm always works with then() and cancel()
			
			msg = "Always responded";
			dfd = new Deferred( function(dfd) {
					initCounters();
					
					// Add the alwaysHandler to the DFD
					
					checkDefaults( dfd ).always( onAlwaysHandler );
				})				
				.notify( "update 6.1" )
				.then( onResultHandler, onErrorHandler, onProgressHandler, onCancelHandler )				
				.cancel( msg );
			
			promise = dfd.promise
						 .always( onAlwaysHandler );
			
			checkResults(promise, false, null, 0);
			checkRejects(promise, false, null, 0);
			checkUpdates(promise, true,  "update 6.1", 1);
			checkCancels(promise, true,  msg,  1);	// Only cancel should change
			
			// notify(), then(), cancel() trigger always() 3x + promise.always()
			// always() attached to promise ignored since dfd is `locked`
			
			checkAlways(promise,true,msg,3);		
		}


		[Test(order=6.2, description="Test Promise::always() works properly after resolve()")]
		public function testAlways_withResolve():void 
		{
			var msg 	: String,
			dfd 	: Deferred,
			promise	: Promise;
			
			// (1) Confirm always works with then() and cancel()
			
			msg = "Always responded";
			dfd = new Deferred( function(dfd) {
					initCounters();
					
					// Add the alwaysHandler to the DFD
					
					checkDefaults( dfd ).always( onAlwaysHandler );
				})				
				.notify( "update 6.2" )
				.then( onResultHandler, onErrorHandler, onProgressHandler, onCancelHandler )				
				.resolve( msg )
				.notify( "update 6.2.b" );
			
			promise = dfd.promise
						 .always( onAlwaysHandler );
			
			checkResults(promise, true,  msg,  1);	// Only cancel should change
			checkRejects(promise, false, null, 0);
			checkUpdates(promise, true,  "update 6.2", 1)
			checkCancels(promise, false, null, 0);
			
			// notify(), then(), cancel() trigger always() 3x + promise.always()
			// always() attached to promise ignored since dfd is `locked`
			
			checkAlways(promise,true,msg,3);		
		}
		
		
		
		
		[Test(order=7.1, description="Test Deferred::pipe() to transform results with resolve()")]
		public function testPipe_forTransform_withResolve():void 
		{
			var dfd    :Deferred = null,
				promise:Promise  = null,
				
				pipeResolver = function( results ) { return "pipeResolve_" + results; },
				pipeRejector = function( results ) { return "pipeReject_"  + results; },
				pipeUpdate   = function( results ) { return "pipeUpdate_"  + results; };
			
			
			// (1) Test Pipe resolveHandler
			
			initCounters();
			
			dfd     = new Deferred().resolve( 1 );
			promise = dfd.pipe( pipeResolver, pipeRejector )
				.then( onResultHandler, onErrorHandler, onProgressHandler);
			
			checkResults(dfd, 	  true,  "1",   			1);	// count == 1 due to .then() above
			checkResults(promise, true,  "pipeResolve_1",   1); // count == 1 due to .then() above
			checkRejects(promise, false,  null, 			0);
			checkUpdates(promise, false,  null, 			0);
			checkCancels(promise, false,  null, 			0);
			
			Assert.assertFalse( "Deferred 'pending' === false",  dfd.pending );
		}
		
		[Test(order=7.2, description="Test Deferred::pipe() to transform results with reject()")]
		public function testPipe_forTransform_withReject():void 
		{
			var dfd    :Deferred = null,
				promise:Promise  = null,
				pipeResolver = function( results ) { return "pipeResolve_" + results; },
				pipeRejector = function( results ) { return "pipeReject_" + results; },
				pipeUpdate   = function( results ) { return "pipeUpdate_" + results; };
			
			
			// (2) Test Pipe rejectHandler 
			
			initCounters();
			
			dfd     = new Deferred().reject( 2 );
			promise = dfd.pipe( pipeResolver, pipeRejector )
				.then( onResultHandler, onErrorHandler, onProgressHandler);
			
			checkResults(promise, false,  null, 			0);
			checkRejects(promise, true,  "pipeReject_2",    1);	// count == 1 due to .then() above
			checkUpdates(promise, false,  null, 			0);
			checkCancels(promise, false,  null, 			0);
			
			Assert.assertFalse( "Deferred 'pending' === false",  dfd.pending );
			
			checkResults(dfd, false,  null, 			0);
			checkRejects(dfd, true,   2, 				1);	// count == 1 due to .then() above
			checkUpdates(dfd, false,  null, 			0);
			checkCancels(dfd, false,  null, 			0);
			
		}
		
		
		[Test(order=7.3, description="Test Deferred::pipe() to transform results with updates & resolve()")]
		public function testPipe_forTransform_withUpdateAndResolve():void 
		{
			var dfd    :Deferred = null,
				promise:Promise  = null,
				pipeResolver = function( results ) { return "pipeResolve_" + results; },
				pipeRejector = function( results ) { return "pipeReject_" + results; },
				pipeUpdate   = function( results ) { return "pipeUpdate_" + results; };
			
			// (3) Test Pipe updateHandler with prior resolve() 
			
			initCounters();
			
			dfd = new Deferred(function(inst:Deferred){
				inst.notify( "3.1")
				.notify( "3.2")		
				.resolve( 3 );
			})
			promise = dfd.pipe( pipeResolver, pipeRejector, pipeUpdate )
				.then( onResultHandler, onErrorHandler, onProgressHandler);
			
			checkResults(promise, true,  "pipeResolve_3",   1);		// count == 1 due to .then() above
			checkRejects(promise, false,  null, 			0);
			checkCancels(promise, false,  null, 			0);
			
			checkUpdates(dfd, 	  true,   "3.2", 			0);		// DFD notified 2x before pipe() but no progressHandler to count
			checkUpdates(promise, false,  null, 			0);		// Last notify NOT piped to Promise since resolve() call before pipe()
			
			Assert.assertFalse( "Deferred 'pending' === false",  dfd.pending );
			
		}
		
		
		[Test(order=7.4, description="Test Deferred::pipe() to transform results with then() & resolve()")]
		public function testPipe_forTransform_withThenAndResolve():void 
		{
			var dfd    :Deferred = null,
				promise:Promise  = null,
				pipeResolver = function( results ) { return "pipeResolve_" + results; },
				pipeRejector = function( results ) { return "pipeReject_" + results; },
				pipeUpdate   = function( results ) { return "pipeUpdate_" + results; };
			
			// (4) Test Pipe updateHandler with resolve() 
			
			initCounters();
			
			dfd      = new Deferred().then( onResultHandler, onErrorHandler, onProgressHandler);
			promise  = dfd.pipe( pipeResolver, pipeRejector, pipeUpdate )
				.then( onResultHandler, onErrorHandler );	// no progressHandler or cancelHandler on pipe
			
			dfd.notify( "4.1" )
				.notify( "4.2" );
			
			checkResults(promise, false,  null, 			0);
			checkRejects(promise, false,  null, 			0);
			checkCancels(promise, false,  null, 			0);
			
			checkUpdates(dfd, 	  true,   "4.2", 			2);	// Deferred has 2 updates from notify()		
			checkUpdates(promise, true,   "pipeUpdate_4.2", 2); // Promise has piped 2 updates from Deferred
			
			dfd.resolve( "4" );
			
			checkResults(dfd,     true,   "4", 				2);	// Just resolved the DFD; counter == 2 due to pipe.then() increment
			checkResults(promise, true,  "pipeResolve_4", 	2); // dfd resolved value piped to promise; not counter increment
			
		}		
		
		[Test(order=7.5, async, timeout="250", description="Test Promise::pipe() asynchronous transforms.")] 
		public function testPipe_forTransform_asynch():void 
		{
			initCounters();
			
			var dfd = new Deferred(),
				promise = dfd.pipe( function( results ) { 
					return "pipeResolve_" + results; 
				})	
				.then( function(data){
					
					checkResults(promise, true,  "pipeResolve_5", 	0); // dfd resolved value piped to promise; not counter increment
					
				}, null,onProgressHandler );
			
			
			Async.delayCall(this, function(){
				dfd.notify( "5.1")
				   .notify( "5.2")
				   .resolve( "5" );
				
				checkUpdates(promise, true, "5.2", 2);
				
			},200);	
		}		
		

		[Test(order=7.6, description="Test Deferred::pipe() to transform results to a reject")]
		public function testPipe_forReject():void 
		{
			initCounters();
			
			var promise : Promise = new Deferred( function(dfd){
					// Simulate response on `original` promise
					dfd.resolve("7");
				})
				.pipe( function(p){
					// Simulate review of response data, identify invalid condition, and
					// `re-throw` a reject() instead
					
					return new Deferred().reject('rejected_'+p);
				})
				.then( onResultHandler, onErrorHandler, onProgressHandler, onCancelHandler);    
			
			
			checkResults(promise, false,  null, 			0);
			checkRejects(promise, true,  "rejected_7",    	1);	// count == 1 due to .then() above
			checkUpdates(promise, false,  null, 			0);
			checkCancels(promise, false,  null, 			0);			
			
		}
		
		[Test(order=7.7, description="Test Deferred::pipe() to chain/sequence promises")]
		public function testPipe_forChains():void 
		{
			initCounters();
			
			var doStep2 = 	function (data) {
					// Notice this uses the results of Step 4
					return new Deferred()
						.then( onResultHandler, onErrorHandler, onProgressHandler, onCancelHandler )
						.notify( "updating Step "+ (data.val+1) )
						.resolve( {title:"Step 5", val:5}  );
				},
				doStep3 = 	function (data) {
					// Notice this uses the results of Step 5
					return new Deferred()
						.then( onResultHandler, onErrorHandler, onProgressHandler, onCancelHandler )
						.notify( "updating Step "+ (data.val+1) )
						.resolve( "Step " + (data.val+1)  );
				};
			
			var promise : Promise = null;
			var dfd     : Deferred = new Deferred( function(inst) {
				// Save reference to final pipe chain promise
				
				promise = inst.then( onResultHandler, onErrorHandler, onProgressHandler, onCancelHandler)
							  .pipe( doStep2 )     // Notice these are not invoked until the dfd is resolved or rejected!
							  .pipe( doStep3 );            
			});
			
			dfd.notify("updating Step 4")     
				.resolve( {title:"Step 4", val:4} );
			
			checkResults(promise, true,  "Step 6", 			3);
			checkRejects(promise, false,  null, 			0);
			checkCancels(promise, false,  null, 			0);						
			
			// NOTE: The piping each deffered called notify BEFORE add to deferred chain/queue, 
			//       This means the first update is last on stack
			
			checkUpdates(promise, true,  "updating Step 4", 3);		
		}		
		
		[Test(order=7.7, description="Test Deferred::pipe() Chaining with nested deferreds")]
		/**
		 * Testing of Promise chaining using the pipe() features.
		 * NOTE: here we are piping only the resolve() response, not the rejected or notify responses
		 */
		public function testPipe_forChains_withNesting():void 
		{
			initCounters();
			
			var dfd     = new Deferred();
			var promise = dfd.then( onResultHandler, onErrorHandler, onProgressHandler )
				.notify("updating Step 7.7")
				.resolve( {title:"Step 7.7", val:7.7} )   // resolve with hashmap [uses pares() method]
				.pipe( function(o){                
					// Notice this uses the results of Step 1
					
					return new Deferred()
								.then( onResultHandler, onErrorHandler, null )
								.notify( "updating Step "+ (o.val+.1) )
								.resolve( {title:"Step ", val:o.val+.1}  )  // resolve with hashmap [uses pares() method]
								.pipe( function(o){                    
									// Notice this uses the results of Step 2
									
									return new Deferred()
												.then( onResultHandler, onErrorHandler, onProgressHandler )
												.notify( "updating Step "+ (o.val+.1) )
												.resolve( "Step " + Number(o.val+.1).toPrecision(2)  );   // resolve with hashmap                  
					});
				});
			
			checkResults(promise, true,  "Step 7.9", 			3);
			checkRejects(promise, false,  null, 			0);
			checkCancels(promise, false,  null, 			0);						
			
			// NOTE: The piping each Deferred called notify() BEFORE add to deferred chain/queue, 
			//       This means the first update is last on stack
			
			checkUpdates(dfd, 	  true,  "updating Step 7.7", 2); 	// dfd has notify() attached
			checkUpdates(promise, false,  null,				  2);	// only 2 progressHandlers attached
		}		
		
		
		[Test(order=7.8, description="Test Deferred::pipe() chain with rejection in sequence")]
		public function testPipe_forChainWithRejection():void 
		{
			initCounters();
			
			var doStepResolve = function (data) {
					// REJECT after notify/update
					
					return new Deferred()
						.then( onResultHandler, onErrorHandler, onProgressHandler, onCancelHandler )
						.notify( "updating Step 8.8" )
						.reject( "Step 8.8" );
				},
				doStep3Rejecting = function (data) {
					
					
					return new Deferred()
						.then( onResultHandler, onErrorHandler, onProgressHandler, onCancelHandler )
						.notify( "updating Step 9.8" )
						.reject( "Step 9.8" );
				};
			
			var promise : Promise = null;
			var dfd     : Deferred = new Deferred( function(inst) {
				// Save reference to final pipe chain promise
				
				promise = inst.pipe( doStepResolve )  
							  .pipe( doStep3Rejecting )
							  .then( onResultHandler, onErrorHandler, onProgressHandler, onCancelHandler);
			});
			
			dfd.notify("updating Step 7.8")     
				.resolve( "Step 7.8" );
			
			// Dfd finished...
			checkResults(dfd, 	  true,  "Step 7.8", 	    0);
			
			// Chain rejected on Step 8.8
			
			checkResults(promise, false,  null, 			0);
			checkRejects(promise, true,  "Step 8.8", 		2);		// 1x from reject() and 1x from onErrorHandler()
			checkCancels(promise, false,  null, 			0);						
			
			// Question: Why is this not `updating Step 8.8` ?
			// Answer:  Step2 notifies BEFORE pipe connects then progress via pipe overwrites with progress from Step1
			
			checkUpdates(promise, true,  "updating Step 7.8", 2);		
			
		}	
		
		[Test(order=8.1, async, timeout="60", description="Test Promise::wait(30)")] 
		public function testWait():void 
		{
			initCounters();
			
			var promise = Promise.wait(20);
			
			Async.delayCall(this, function(){
				
				checkResults(promise, true,  null, 0); // Promise resolved with resolve() == null

				checkRejects(promise, false, null, 0);
				checkUpdates(promise, false, null, 0);
				checkCancels(promise, false, null, 0);
				
				
			},40);	
		}		
		
		
		[Test(order=8.2, async, timeout="70", description="Test Promise::wait(delay,...params)")] 
		public function testWait_withParams():void 
		{
			initCounters();
			
			var promise = Promise.wait(30,"Param 1",8.1);
			
			Async.delayCall(this, function(){
				
				checkRejects(promise, false, null, 0);
				checkUpdates(promise, false, null, 0);
				checkCancels(promise, false, null, 0);
				
				checkResults(promise, true,  promise.result, 0); // Promise resolved with resolve() 
				
				Assert.assertEquals("Promise results[0] == 'Param 1'",	"Param 1", 	promise.result[0]);
				Assert.assertEquals("Promise results[0] == 8.1",		8.1, 		promise.result[1]);
				
			},40);	
		}	
		
		[Test(order=8.3, async, timeout="60", description="Test Promise::wait(delay,<function>)")] 
		public function testWait_withFunction():void 
		{
			initCounters();
			
			var value    = null,
				promise  = Promise.wait(30, function() {
					
					// Set closure value for later use.
					value    = 8.3;
					
					// ::wait() will resolve with return value of function
					return "wait 8.3 resolved";
				})
			
			Async.delayCall(this, function(){
				
				checkRejects(promise, false, null, 0);
				checkUpdates(promise, false, null, 0);
				checkCancels(promise, false, null, 0);
				
				checkResults(promise, true,  "wait 8.3 resolved" ,0);  
				
				Assert.assertEquals("Promise wait handler fired.",	8.3, value);
				
			},40);	
		}	
		
		[Test(order=8.4, async, timeout="90", description="Test Promise::wait(delay,<function>,...params)")] 
		public function testWait_withFunctionAndParams():void 
		{
			initCounters();
			
			var msg      = "wait 8.4 resolved",
				value    = null,
				promise  = Promise.wait(30, function( data:Object, msg:String ) {
									// Set closure value for later use.
									// ::wait() will resolve with return value of function
									
									value = data.val;
									return msg;
									
								}, {val:8.4}, msg )			// pass in params to be used as args to func handler
								.then( onResultHandler );	// when resolved, incremeent result counter
			
			Async.delayCall(this, function(){
				
				checkResults(promise, true,  msg,  1);  
				checkRejects(promise, false, null, 0);
				checkUpdates(promise, false, null, 0);
				checkCancels(promise, false, null, 0);
				
				Assert.assertEquals("Promise wait handler fired.",	8.4, value);
				
			},50);	
		}	
		

		[Test(order=9.1, async, timeout="100", description="Test Promise::when()")] 
		public function testWhen_withResolves():void 
		{
			initCounters();
			
			var p1Result = "promise 1 result",
				p2Result = "promise 2 result",
				promise1 = Promise.wait(30, p1Result).then( onResultHandler ),
				promise2 = Promise.wait(45, p2Result).then( onResultHandler ),
				
				// Now create when() batch set...
				
				batch    = Promise.when( promise1, promise2 )
					              .then( onResultHandler );
				
			Async.delayCall(this, function(){
				
				checkResults(batch, true,  batch.result,  3);
				
				// Batched results are stored in array... in order submitted to when(...)
				
				Assert.assertEquals("batch results[0] == p1Result", p1Result, batch.result[0] );
				Assert.assertEquals("batch results[1] == p2Result", p2Result, batch.result[1] );
				
				checkRejects(batch, false, null, 0);
				checkUpdates(batch, false, null, 0);
				checkCancels(batch, false, null, 0);
				
			},50);	
		}	
		
		[Test(order=9.2, async, timeout="100", description="Test Promise::when() with rejection")] 
		/**
		 * Test a promise rejection will stop all futures and report properly in
		 * the when() handlers assigned. 
		 */
		public function testWhen_withReject():void 
		{
			initCounters();
			
			var promise1 = 	Promise.wait(30, "resolved_p1")
								   .then( onResultHandler ),
								   
				promise2 = 	new Deferred( function(dfd) {
									dfd.reject("rejected_2");
							}).promise,
				
				promise3 =  new Deferred( function(dfd) {
								Promise.wait(45,"resolved_p3_i")
								       .then(function(){
										 dfd.resolve("resolved_p3");  
									   });
							}).promise,
				
				// Now create when() batch set...
				
				batch    = Promise.when( promise1, promise2, promise3 )
								  .then( onResultHandler, onErrorHandler );
			
			Async.delayCall(this, function(){
				
				checkResults(batch, false,  null,  		 1);
				checkRejects(batch, true,  'rejected_2', 1);
				
				checkUpdates(batch, false, null, 0);
				checkCancels(batch, false, null, 0);
				
			},50);	
		}
		
		[Test(order=9.3, description="Test Promise::when() with cancel")] 
		/**
		 * Test a promise cancellation will still propogate properly to a
		 * when() handlers assigned via when().then() or when().done(). 
		 */
		public function testWhen_withCancel():void 
		{
			initCounters();
			
			var promise1 = 	Promise.wait(30, "resolved_p1")
								   .then( onResultHandler ),
				
				promise2 = 	new Deferred( function(dfd) {
								dfd.cancel("cancel_2");
							}).promise,
				
				promise3 =  new Deferred( function(dfd) {
								dfd.reject("reject_3");
							}).promise,
				
				// Now create when() batch set...
								   
				batch    = Promise.when( promise1, promise2, promise3 )
								  .then( onResultHandler, onErrorHandler, null, onCancelHandler );
			
			checkResults(batch, false,  null,  		0);
			checkRejects(batch, false, 	null, 		0);	// cancelled first; so rejection is ignored
			checkUpdates(batch, false, 	null, 		0);
			checkCancels(batch, true,  'cancel_2', 	1);
		}
		
		[Test(order=9.4, async, timeout="100", description="Test Promise::when() with functions")] 
		public function testWhen_withFunction():void 
		{
			initCounters();
			
			var p1Result = "promise 1 result",
				p2Result = null,
				
				// Wait asynchronously for 30 frames
				
				promise1 = Promise.wait(30, p1Result).then( onResultHandler ),
				func2Call= function(){ p2Result = "promise 2 result"; },
				
				batch = Promise.when( promise1, func2Call )
							   .then( onResultHandler );
			
			Async.delayCall(this, function(){
				
				checkResults(batch, true,  batch.result,  2);
				
				// Batched results are stored in array... in order submitted to when(...)
				// NOTE: functions in a when() resolve to `null` 
				
				Assert.assertEquals("batch results[0] == p1Result", p1Result, batch.result[0] );
				Assert.assertEquals("batch results[1] == p2Result", null, batch.result[1] );
				
				checkRejects(batch, false, null, 0);
				checkUpdates(batch, false, null, 0);
				checkCancels(batch, false, null, 0);
				
			},50);	
		}
		

		[Test(order=9.5, async, timeout="150", description="Test Promise::when() with params")] 
		public function testWhen_withParams():void 
		{
			initCounters();
			
			var p1Result = "promise 1 result",
				promise1 = Promise.wait(30, p1Result).then( onResultHandler ),
				
				batch = Promise.when( promise1, 9.5 )
			  				   .then( onResultHandler );
			
			Async.delayCall(this, function(){
				
				checkResults(batch, true,  batch.result,  2);
				
				// Batched results are stored in array... in order submitted to when(...)
				
				Assert.assertEquals("batch results[0] == p1Result", p1Result, batch.result[0] );
				Assert.assertEquals("batch results[1] == 9.5", 		9.5, 	  batch.result[1] );
				
				checkRejects(batch, false, null, 0);
				checkUpdates(batch, false, null, 0);
				checkCancels(batch, false, null, 0);
				
			},50);	
		}

		
		[Test(order=10.1, description="Test Promise::watch(asyncToken) with ResultEvent")] 
		public function testWatch_asyncTokenWithResults():void 
		{
			initCounters();
			
			var msg    : String      = "rpc responded via token";
			var token  : AsyncToken  = new AsyncToken();
			
			// Be sure to pipe the response to get only the msg value...
			
			var promise: Promise     = Promise.watch( token )
											  .pipe( function (response) {	
													return ResultEvent(response).result;				
											  })
											  .then( onResultHandler );
			
			// Simulate RPC response announced via token 
			token.mx_internal::applyResult( 
				new ResultEvent( ResultEvent.RESULT, false, false, msg, token ) 
			);
			
				// Now check the promise state 
				checkResults(promise, true,  msg, 1);
				checkRejects(promise, false, null, 0);
				checkUpdates(promise, false, null, 0);
				checkCancels(promise, false, null, 0);
		}
		
		[Test(order=10.2, description="Test Promise::watch(asyncToken) with FaultEvent")] 
		public function testWatch_asyncTokenWithFault():void 
		{
			initCounters();
			
			var msg    : String      = "rpc faulted via token";
			var token  : AsyncToken  = new AsyncToken();
			
			// Be sure to pipe the response to get only the msg value...
			
			var promise: Promise     = Promise.watch( token )
											  .pipe( null, function (response) {	
													return FaultEvent(response).fault.faultString;				
												})
											  .then( onResultHandler, onErrorHandler );
			
			
			// Simulate RPC fault announced via token 
			
			var fault  : Fault      = new Fault("fault", msg );
			var fEvent : FaultEvent = new FaultEvent(FaultEvent.FAULT,false,false, fault, token); 
			
			token.mx_internal::applyFault( fEvent );
			
				// Now check the promise state 
				checkResults(promise, false, null, 0);
				checkRejects(promise, true,  msg,  1);
				checkUpdates(promise, false, null, 0);
				checkCancels(promise, false, null, 0);
		}
		
		[Test(order=10.3, async, timeout="95", description="Test Promise::watch(<eventDispatcher>)")] 
		/**
		 * Test Promise::watch() using a resultEventType string
		 */
		public function testWatch_eventDispatcherWithResultEventType():void 
		{
			initCounters();
			
			var start  : Number      = new Date().milliseconds;
			var end    : Number      = null;
			var msg    : String      = "rpc faulted via token";
			var timer  : Timer		 = new Timer(10,1);
			
			// Be sure to pipe the response to get only the msg value...
			
			var promise: Promise     =   Promise.watch( timer, TimerEvent.TIMER_COMPLETE )
												.pipe( function(event) {
													end = new Date().milliseconds;
													return (end - start) > 10 ? "timerComplete" : "";
												})
												.then( onResultHandler, onErrorHandler );
			timer.start();
			
			Async.delayCall(this, function(){
				
				// Now check the promise state 
				checkResults(promise, true,  "timerComplete", 1);
				checkRejects(promise, false, null, 0);
				checkUpdates(promise, false, null, 0);
				checkCancels(promise, false, null, 0);
				
			}, 25 );	
		}	
		
		
		[Test(order=10.4, async, timeout="85", description="Test Promise::watch(<eventDispatcher>,null,<options>)")] 
		/**
		 * Test Promise::watch() using a resultEventType and progressEventType strings
		 */
		public function testWatch_eventDispatcherWithProgress():void 
		{
			initCounters();
			
			var timer  : Timer		 = new Timer(5,3);
			
			// Be sure to pipe the response to get only the msg value...
			
			var onTimer		: Function    =  function(event:TimerEvent) { return event.type; };
			var promise		: Promise     =  Promise.watch( timer, TimerEvent.TIMER_COMPLETE, null, TimerEvent.TIMER)
													.pipe( onTimer, null, onTimer )
													.then( onResultHandler, onErrorHandler, onProgressHandler );
			timer.start();
			
			Async.delayCall(this, function(){
				
				// Now check the promise state 
				checkResults(promise, true,  "timerComplete", 1);
				checkRejects(promise, false, null, 0);
				checkUpdates(promise, true,  "timer", 3);
				checkCancels(promise, false, null, 0);
				
			}, 55 );	
		}
		
		// *****************************************************************************
		// Protected Methods
		// *****************************************************************************
		
		protected function onResultHandler(promise:*, val:*):void	{	resultHitCount++;	alwaysHitCount++; }
		protected function onErrorHandler( promise:*, val:*):void	{	errorHitCount++;	alwaysHitCount++; }
		protected function onProgressHandler(promise:*, val:*):void	{	progressHitCount++;					  }
		protected function onCancelHandler(promise:*, val:*):void	{	cancelHitCount++;	alwaysHitCount++; }
		
		protected function onAlwaysHandler(promise:*, val:*):void	{	alwaysHitCount++; alwaysReponse = val;	}
		
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
		
		private function checkDefaults(target:Object):Object {
			
			checkResults(target, false, null, 0);
			checkRejects(target, false, null, 0);
			checkCancels(target, false, null, 0);
			checkUpdates(target, false, null, 0);
			checkAlways(target, false, null, 0);
			
			if (target is Promise)
				Assert.assertFalse( "Promise has not resolved.", 	 target.resolved);
			
			return target;
		}
		
		private function checkResults(promise:Object, state:Boolean, response:*=null,count:int=0):void {
				
				Assert.assertEquals( "Deferred has `result` == " + response, 	response, promise.result 	);
				Assert.assertEquals( "Deferred has 'succeeded' ==" + state, 	state   , promise.resolved 	);
				Assert.assertEquals( "Deferred has resultHitCount ==" +count,  	count   , resultHitCount  	);
		}
		
		private function checkRejects(promise:Object, state:Boolean,response:*=null,count:int=0):void {
			
			Assert.assertEquals( "Deferred has `error` == " + response, 	response, promise.error 	);
			Assert.assertTrue( "Deferred has 'failed' ==" + state, 			state   , promise.rejected	);
			Assert.assertEquals( "Deferred has errorHitCount ==" +count,  	count   , errorHitCount );
		}
		
		private function checkCancels(promise:Object, state:Boolean,response:*=null,count:int=0):void {
			
			Assert.assertEquals( "Deferred has `reason` == " + response, 	response, 	promise.reason 	 	);
			Assert.assertEquals( "Deferred has 'cancelled' ==" + state, 	state, 		promise.cancelled 	);
			Assert.assertEquals( "Deferred has cancelHitCount ==" +count,  	count, 		cancelHitCount  );
		}
		
		private function checkUpdates(promise:Object, state:Boolean,response:*=null,count:int=0):void {
			
			Assert.assertEquals( "Deferred has `progress` == " + response, 	response, promise.status 	 	);
			Assert.assertEquals( "Deferred has progressHitCount ==" +count, count   , progressHitCount  );
		}
		
		
		private function checkAlways(promise:Object, state:Boolean,response:*=null,count:int=0):void {
			
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