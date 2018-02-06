package pman.ipc;

import tannus.io.*;
import tannus.ds.*;
import tannus.math.Random;
import tannus.graphics.Color;
import tannus.node.ChildProcess;

import crayon.*;

import electron.ext.*;
import electron.renderer.IpcRenderer as Ipc;
import electron.ext.Dialog;
import electron.Tools.defer;

import pman.LaunchInfo;
import pman.core.*;
import pman.ui.*;
import pman.db.*;
import pman.events.*;
import pman.media.*;
import pman.ww.Worker;

import Std.*;
import tannus.internal.CompileTime in Ct;
import tannus.TSys as Sys;
import edis.Globals.*;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;

class RendererIpcCommands extends BaseIpcCommands {
    /* Constructor Function */
    public function new(m : BPlayerMain):Void {
        super();

        this.main = m;
    }

/* === Instance Methods === */

    /**
      * bind commands
      */
    public function bind():Void {
        fbind('OpenFile', player.selectAndOpenFiles);
        fbind('OpenDirectory', player.selectAndOpenDirectory);
        fbind('ExportPlaylist', player.exportPlaylist);
        fbind('TogglePlaylist', player.togglePlaylist);
        fbind('ClearPlaylist', player.clearPlaylist);
        fbind('ShufflePlaylist', player.shufflePlaylist);
        fbind('SavePlaylist', player.savePlaylist);
        fbind('LoadPlaylist', player.loadPlaylist);
        fbind('Snapshot', player.snapshot);
        fbind('EditPreferences', player.editPreferences);
        fbind('EditMarks', player.editBookmarks);
        fbind('AddComponent', function(name: String) {
            switch ( name ) {
                case 'skim':
                    player.skim();

                default:
                    return ;
            }
        });
        fbind('Exec', function(code: String) {
            player.exec(code, function(?error) {
                return ;
            });
        });
        fbind('Notify', dialogs.notify);
        fbind('Notify:Player', function(sdata: String) {
            var data:Dynamic = sdata;
            if (sdata.has('{') && sdata.has('}')) {
                data = haxe.Json.parse( sdata );
            }
            player.message(
                if (Std.is(data, String))
                    (cast data)
                else
                    (pman.ui.PlayerMessageBoard.messageOptionsFromJson(untyped data))
            );
        });
        fbind('Tab:Select', player.session.setTab);
        fbind('Tab:Create', player.session.newTab);
        fbind('Tab:Delete', player.session.deleteTab);
    }

/* === Utils === */

/* === Overrides === */

    override function _post(channel:String, data:Dynamic):Void {
        Ipc.send(channel, data);
    }

    override function _onMessage(channel:String, handler:Dynamic->Void):Void {
        Ipc.on(channel, function(event, ?packet:Dynamic) {
            handler( packet );
        });
    }

/* === Computed Instance Fields === */

    public var player(get, never):Player;
    private inline function get_player() return main.player;

/* === Instance Fields === */

    public var main : BPlayerMain;
}
