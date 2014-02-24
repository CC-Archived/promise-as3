package com.codecatalyst.promise.adapter
{
    import com.codecatalyst.promise.Promise;

    /**
     * Global auto-registration function that
     * centralizes regsitration of promise.adapters <xxx>Adapter classes
     *
     */
    public function registerAdpaters():void {

        Promise.registerAdapter( DispatcherAdapter.adapt );
        Promise.registerAdapter( URLLoaderAdapter.adapt  );
    }
}
