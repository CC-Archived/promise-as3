//------------------------------------------------------------------------------
//  Copyright (c) 2009-2013 the original author or authors. All Rights Reserved. 
// 
//  NOTICE: You are permitted to use, modify, and distribute this file 
//  in accordance with the terms of the license agreement accompanying it. 
//------------------------------------------------------------------------------

package com.codecatalyst.promise
{
	import mx.core.mx_internal;
	import mx.rpc.AsyncToken;
	import mx.rpc.Fault;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import org.flexunit.async.Async;
	import org.hamcrest.assertThat;
	import org.hamcrest.object.equalTo;

	use namespace mx_internal;

	public class AsyncTokenAdapterTest
	{

		/*============================================================================*/
		/* Private Properties                                                         */
		/*============================================================================*/

		private const sentinel:Object = {sentinel: "sentinel"};

		private var token:AsyncToken;

		/*============================================================================*/
		/* Test Setup and Teardown                                                    */
		/*============================================================================*/

		[Before]
		public function before():void
		{
			token = new AsyncToken();
			Promise.registerAdapter(AsyncTokenAdapter);
		}

		[After]
		public function after():void
		{
			Promise.removeAdapter(AsyncTokenAdapter);
		}

		/*============================================================================*/
		/* Tests                                                                      */
		/*============================================================================*/

		[Test(async)]
		public function adapt_result():void
		{
			var actual:* = null;

			const complete:Function = Async.asyncHandler(this, function():void {
				assertThat(actual, equalTo(sentinel));
			}, 250);

			Promise.when(token)
				.then(function(value:*):void {
					actual = value;
					complete();
				});

			token.applyResult(new ResultEvent(ResultEvent.RESULT, false, false, sentinel));
		}

		[Test(async)]
		public function adapt_fault():void
		{
			var actual:* = null;
			const fault:Fault = new Fault("faultCode", "faultString");

			const complete:Function = Async.asyncHandler(this, function():void {
				assertThat(actual, equalTo(fault));
			}, 250);

			Promise.when(token)
				.then(null, function(reason:*):void {
					actual = reason;
					complete();
				});

			token.applyFault(new FaultEvent(FaultEvent.FAULT, false, false, fault));
		}
	}
}
