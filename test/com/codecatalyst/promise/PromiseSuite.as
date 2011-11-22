package com.codecatalyst.promise
{
	import com.codecatalyst.promise.tests.TestCallbacks;
	import com.codecatalyst.promise.tests.TestDeferred;
	import com.codecatalyst.promise.tests.TestPromise;
	import com.codecatalyst.promise.tests.TestjQuery;
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class PromiseSuite
	{
		public var test1 : com.codecatalyst.promise.tests.TestDeferred;
		public var test2 : com.codecatalyst.promise.tests.TestPromise;
		public var test3 : com.codecatalyst.promise.tests.TestjQuery;
		public var test4 : com.codecatalyst.promise.tests.TestCallbacks;
		
	}
}