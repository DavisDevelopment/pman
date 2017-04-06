package pman.ipc;

import tannus.io.*;
import tannus.ds.*;

import electron.main.IpcMain as Ipc;
import electron.main.BrowserWindow;
import electron.*;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;

class MainIpcCommands {
    /* Constructor Function */
    public function new(bg : Background):Void {
        this.bg = bg;
    }

/* === Instance Methods === */

    /**
      * bind commands
      */
    public function bind():Void {
        inline function b(name, f) Ipc.on('command:$name', f);

        b('UpdateMenu', function() bg.updateMenu());
    }

    /**
      * send command
      */
    public function send(w:BrowserWindow, cmd:String, ?args:Array<Dynamic>):Void {
        var params:Array<Dynamic> = ['command:$cmd'];
        if (args != null)
            params = params.concat( args );
        Reflect.callMethod(w.webContents, w.webContents.send, params);
    }

/* === Instance Fields === */

    public var bg : Background;
}
