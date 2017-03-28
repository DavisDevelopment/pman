package pman;

import tannus.io.*;
import tannus.geom.*;
import tannus.events.*;
import tannus.sys.*;
import tannus.media.Duration;

import electron.ext.*;
import electron.ext.Dialog;

import Slambda.fn;
import tannus.math.TMath.*;

using StringTools;
using Lambda;
using Slambda;
using tannus.math.TMath;

class Tools {
    /**
      * convert file size to human readable form
      */
    public static function formatSize(bytes:Float, si:Bool=true):String {
        var thresh:Int = (si ? 1000 : 1024);
        if (abs( bytes ) < thresh) {
            return (bytes + 'B');
        }
        var units : Array<String>;
        if ( si ) {
            units = ['kB','MB','GB','TB','PB','EB','ZB','YB'];
        }
        else {
            units = ['KiB','MiB','GiB','TiB','PiB','EiB','ZiB','YiB'];
        }
        var u = -1;
        do {
            bytes /= thresh;
            ++u;
        } while (abs( bytes ) >= thresh && u < units.length - 1);
        return (bytes.toFixed( 1 ) + ' ' + units[u]);
    }
}
