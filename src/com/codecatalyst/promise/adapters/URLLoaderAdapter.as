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

package com.codecatalyst.promise.adapters
{
    import com.codecatalyst.promise.Promise;

    import flash.net.URLLoader;

    /**
     * URLLoaderAdapter is an adapter used to enable
     * <code>Promise.when()</code> to convert UrlLoader operations to Promises.
     *
     * To register this adapter:
     * <code>Promise.registerAdapter(URLLoaderAdapter.adapt)</code>
     * To unregister this adapter:
     * <code>Promise.removeAdapter(URLLoaderAdapter.adapt)</code>
     *
     * Usage example:
     * <code>
     *     var readMeURL = "https://raw.github.com/ThomasBurleson/promise-as3/master/README.md"
     *     var loader = new URLLoader();
     *
     *         loader.load( new URLRequest( readMeURL ) );
     *
     *         Promise.when( loader )
     *                .then(
     *                      function onImageLoaded( docReadMe:String ):void {
     *                          // Do something with this ReadMe.md data...
     *                      },
     *                      function onLoadError( errorID:String ):void {
     *                         // Report the error loading the ReadMe.md document
     *                     }
     *                 );
     *</code>
     *
     */
    public class URLLoaderAdapter
    {
        /**
         *
         * @param value
         * @return
         */
        public static function adapt( value:* ):Promise
        {
            const loader:URLLoader = value as URLLoader;

            return loader ? new DeferredLoader( loader ).promise : null;
        }

        // ******************************************************
        // Protected, internal Static features
        // ******************************************************

        /**
         * Activator to register this adapter with the Promise when() adaptor registry
         * @return
         */
        protected static function initialize():Boolean
        {
            Promise.registerAdapter( URLLoaderAdapter.adapt );
            return true;
        }

        /**
         * Auto-register the `adapt` function for Promise.when()
         */
        protected static var _initialized : Boolean = initialize();
    }
}

import com.codecatalyst.promise.Deferred;
import com.codecatalyst.promise.Promise;

import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.net.URLLoader;

/**
 * Wrapper class for URLLoader that internally manages listeners and
 * resolve/reject actions on the publish Deferred/Promise instance
 *
 */
class DeferredLoader {

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

    public function DeferredLoader( loader: URLLoader )
    {
        _loader   = loader;
        _deferred = new Deferred();

        attachListeners();
    }

    // *******************************************************
    // Protected Methods
    // *******************************************************

    protected function attachListeners( active:Boolean=true ):void
    {
        if ( !_loader ) return;

        if ( active )
        {
            _loader.addEventListener( Event.COMPLETE,                       onLoadComplete );
            _loader.addEventListener( IOErrorEvent.IO_ERROR,                onLoadError    );
            _loader.addEventListener( SecurityErrorEvent.SECURITY_ERROR,    onLoadError    );

        } else {

            _loader.removeEventListener( Event.COMPLETE,                    onLoadComplete );
            _loader.removeEventListener( IOErrorEvent.IO_ERROR,             onLoadError    );
            _loader.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, onLoadError    );

            _loader = null;
        }
    }


    // *******************************************************
    // Protected Event Handlers
    // *******************************************************

    /**
     * Load has completed. Resolve with the `data` and cleanup.
     *
     */
    protected function onLoadComplete(event:Event):void
    {
        try {

            // Extract the `data` and resolve the deferred
            _deferred.resolve( event.target.data );

        } finally {

            attachListeners( false );
            _deferred = null;
        }
    }

    /**
     * A Security or IO error event occurred. Reject the deferred
     * and cleanup.
     */
    protected function onLoadError(event:Object):void
    {
        try {

            // Extract the `errorID` and reject the deferred
            _deferred.reject( event["errorID"] );

        } finally {

            attachListeners( false );
            _deferred = null;
        }
    }


    // ****************************************************
    // Protected Attributes
    // ****************************************************

    protected var _loader   : URLLoader;
    protected var _deferred : Deferred;
}
