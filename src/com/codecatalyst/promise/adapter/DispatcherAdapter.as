////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2013 CodeCatalyst, LLC - http://www.codecatalyst.com/
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
////////////////////////////////////////////////////////////////////////////////

package com.codecatalyst.promise.adapter
{
    import com.codecatalyst.promise.Promise;
    import com.codecatalyst.promise.inteceptors.EventIntercepter;

    /**
     * DispatcherAdapter is an adapter used to enable
     * <code>Promise.when()</code> to convert any EventDispatcher activity to Promise activity.
     *
     * NOTE: To properly determine which events will `resolve()` versus which events will `reject()`
     *       the <code>EventIntercepter</code> is required to wrap the eventDispatcher instance
     *
     *       An additional benefit of the intercepter is that specific data can be auto-extracted from
     *       the events and will be used within the resolve/reject processes.
     *
     * To register this adapter:
     * <code>Promise.registerAdapter(DispatcherAdapter.adapt)</code>
     * To unregister this adapter:
     * <code>Promise.removeAdapter(DispatcherAdapter.adapt)</code>
     *
     * Usage example:
     * <code>
     *
     *     // The EventIntercepter listens for specific events from authenticator
     *     // and extracts data based on
     *     // the specified keys; e.g. `session` and `details`
     *
     *     function loginUser( userName:String, password:String ):Promise
     *     {
     *          var authenticator : Authenticator = new Authenticator;
     *
     *              authenticator.loginUser( userName, password );
     *
     *         return Promise.when( new EventIntercepter (
     *                  authenticator,
     *                  AuthenticationEvent.AUTHENTICATED, 'session',
     *                  AuthenticationEvent.NOT_ALLOWED,   'details'
     *         ));
     *     }
     *
     *
     *     loginUser(
     *          'ThomasB',
     *          "superSecretPassword"
     *     )
     *     .then(
     *
     *         function onLoginOK( session:Object ):void {
     *             // Save the session information and continue login process
     *         },
     *
     *         function onLoginFailed( fault:Object  ):void {
     *            // Report the login failure and request another attempt
     *         }
     *
     *     );
     *
     *</code>
     *
     */
    public class DispatcherAdapter
    {
        // ******************************************************
        // Public Static `adapt()` feature
        // ******************************************************

        /**
         * Adapt the EventIntercepter to a promise...
         * @param value EventIntercepter
         * @return
         */
        public static function adapt( value:* ):Promise
        {
            var interceptor : * = value as EventIntercepter;

            return interceptor ? new DeferredDispatcher( interceptor ).promise : null;
        }

    }
}

import com.codecatalyst.promise.Deferred;
import com.codecatalyst.promise.Promise;
import com.codecatalyst.promise.inteceptors.EventIntercepter;

/**
 * Wrapper class for URLLoader that internally manages listeners and
 * resolve/reject actions on the publish Deferred/Promise instance
 *
 */
class DeferredDispatcher {

    /**
     * Promise of the future value of this Responder.
     */
    public function get promise():Promise
    {
      return _deferred.promise;
    }

    // ******************************************************
    // Constructor
    // ******************************************************

    public function DeferredDispatcher( intercepter : EventIntercepter )
    {
        _intercepter = intercepter;
        _deferred    = new Deferred();

        attachListeners();
    }

    // *******************************************************
    // Protected Methods
    // *******************************************************

    protected function attachListeners( active:Boolean=true ):void
    {
        if ( !_intercepter ) return;

        if ( active )
        {
            _intercepter.addCallbacks(
                onResultHander,
                onFaultHandler,
                this
            );

        } else {

            _intercepter.release( );
            _intercepter = null;
        }
    }


    // *******************************************************
    // Protected Event Handlers
    // *******************************************************

    /**
     * Load has completed. Resolve with the `data` and cleanup.
     *
     */
    protected function onResultHander( result:* ):void
    {
        try {

            // Extract the `data` and resolve the deferred
            _deferred.resolve( result );

        } finally {

            attachListeners( false );
            _deferred = null;
        }
    }

    /**
     * A Security or IO error event occurred. Reject the deferred
     * and cleanup.
     */
    protected function onFaultHandler( fault:* ):void
    {
        try {

            // Extract the `errorID` and reject the deferred
            _deferred.reject( fault );

        } finally {

            attachListeners( false );
            _deferred = null;
        }
    }


    // ****************************************************
    // Protected Attributes
    // ****************************************************

    protected var _intercepter  : EventIntercepter;
    protected var _deferred     : Deferred;
}
