package pman.tools.chromecast;

import tannus.node.*;

import tannus.io.*;
import tannus.ds.*;

import pman.async.*;

import Slambda.fn;

using Slambda;

@:forward
abstract Browser (ExtBrowser) from ExtBrowser {
    public inline function new() {
        this = new ExtBrowser();
    }

    public function onDevice(handler : Device->Void):Void {
        this.onDevice(fn(d=>handler(new Device(d))));
    }
}
