package pman.tools.localip;

import js.Lib.require;
import pman.async.*;

class LocalIp {
    private static var localip:Dynamic = {require('local-ip');};

    public static inline function get(networkInterface:String, callback:Cb<String>):Void {
        localip(networkInterface, callback);
    }
}
