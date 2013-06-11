package com.codecatalyst.promise.adapters
{
    import com.codecatalyst.promise.adapters.*;
    import com.codecatalyst.promise.Promise;

    /**
     * Global auto-registration function that
     * centralizes regsitration of promise.adapters <xxx>Adapter classes
     *
     */
    public function registerAdpaters():void {

        Promise.registerAdapter( AsyncTokenAdapter.adapt );
        Promise.registerAdapter( DispatcherAdapter.adapt );
        Promise.registerAdapter( URLLoaderAdapter.adapt  );
    }
}
