package ;

import tannus.ds.*;
import tannus.ds.tuples.*;
import tannus.sys.Path;
import tannus.node.Fs as NodeFs;

import electron.main.*;
import electron.main.Menu;
import electron.main.MenuItem;
import electron.ext.App;
import electron.Tools.defer;

import js.html.Window;

import tannus.TSys as Sys;

import pman.db.AppDir;
import pman.ww.*;
import pman.server.*;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;

class ServerMain extends Worker {
    /* Constructor Function */
    public function new():Void {
        super();

        server = new Server( this );
    }

/* === Instance Methods === */

    /**
      * start [this] worker
      */
    override function start():Void {
        super.start();
    }

    override function onPacket(packet : WorkerPacket):Void {
        switch ( packet.type ) {
            case 'init':
                var initData:ServerInitData = packet.data;
                server.init( initData );

            case 'close':
                server.stop();

            default:
                trace( packet );
        }
    }

/* === Instance Fields === */

    public var server : Server;

/* === Static Methods === */

    public static function main():Void {
        new ServerMain().start();
    }
}
