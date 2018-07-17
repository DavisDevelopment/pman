package pman.pmbash.commands;

import tannus.io.*;
import tannus.ds.*;
import tannus.TSys as Sys;

import pman.core.*;
import pman.async.*;
import pman.format.pmsh.*;
import pman.format.pmsh.Token;
import pman.format.pmsh.Expr;
import pman.format.pmsh.Cmd;
import pman.pmbash.commands.*;

//import electron.Tools.*;
import edis.Globals.*;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.async.VoidAsyncs;

/**
  command-set for working with PMan's playlist system
 **/
class PlaylistCommand extends HierCommand {
    override function _build_() {
        inline function cmd(self:HierCommand, name, f) self.subCmd(name, onlyArgs(f));
        function pcmd(self:HierCommand, name, f) {
            self.createSubCommand(name, {}, function(c) {
                c.pythonicMain( f );
            });
        }

        cmd(this, 'export', cmdExport);
        cmd(this, 'save', cmdSave);
        cmd(this, 'open, load', cmdOpen);
        cmd(this, 'shuffle', cmdShuffle);
        cmd(this, 'delete', cmdDelete);
    }

    function cmdExport(argv:Array<CmdArg>, done:VoidCb) {
        player.exportPlaylist(function() {
            done();
        });
    }

    function cmdSave(argv:Array<CmdArg>, done:VoidCb) {
        var name:String = null;
        if (!argv.empty())
            name = argumentString(argv[0]);
        player.savePlaylist(null, name, function() {
            done();
        });
    }

    function cmdOpen(argv:Array<CmdArg>, done:VoidCb) {
        if (argv.empty()) {
            done();
        }
        else {
            player.loadPlaylist(argumentString(argv[0]), function() {
                done();
            });
        }
    }

    function cmdShuffle(argv:Array<CmdArg>, done:VoidCb) {
        player.shufflePlaylist();
        done();
    }

    function cmdDelete(argv:Array<CmdArg>, done:VoidCb) {
        if (argv.empty()) {
            done();
        }
        else {
            try {
                var plfile = player.app.appDir.playlistFile(argumentString(argv[0]));
                plfile.delete();
                done();
            }
            catch (err: Dynamic) {
                report( err );
                done();
            }
        }
    }
}

class OldPlaylistCommand extends Command {
    override function execute(i:Interpreter, argv:Array<CmdArg>, done:VoidCb):Void {
        var args = argv.map.fn( _.value );
        var action:String = args.shift();
        if (action == null) {
            return done();
        }
        else {
            switch ( action ) {
                case 'clear':
                    player.clearPlaylist();
                    done();

                case 'export':
                    player.exportPlaylist(function() done());

                case 'save':
                    var name:Null<String> = args.shift();
                    player.savePlaylist(null, name, function() done());

                case 'open':
                    var name:Null<String> = args.shift();
                    if (name != null) {
                        player.loadPlaylist(name, function() done());
                    }
                    else done();

                case 'shuffle':
                    player.shufflePlaylist();
                    done();

                case 'delete', 'del', 'remove', 'rm':
                    var name = args.shift();
                    try {
                        var plfile = player.app.appDir.playlistFile( name );
                        plfile.delete();
                        done();
                    }
                    catch (error : Dynamic) {
                        done();
                    }

                default:
                    done();
            }
        }
    }
}
