package pman.tools.mdns;

import tannus.node.*;

@:jsRequire('mdns', 'Browser')
extern class MDNSBrowser extends EventEmitter {
    /* Constructor Function */
    public function new(serviceType:ServiceType, options:Dynamic):Void;
    public function start():Void;
    public static function create(serviceType : ServiceType):MDNSBrowser;

    inline public function onServiceUp(f : MDNSService->Dynamic->Void):Void {
        on('serviceUp', f);
    }
    inline public function onServiceChanged(f : MDNSService->Dynamic->Void):Void {
        on('serviceChanged', f);
    }
    inline public function onError(f : Dynamic->MDNSService->Void):Void {
        on('error', f);
    }
}
