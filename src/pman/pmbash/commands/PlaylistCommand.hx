package pman.pmbash.commands;

import tannus.io.*;
import tannus.ds.*;
import tannus.TSys as Sys;

import pman.core.*;
import pman.async.*;
import pman.format.pmsh.*;
import pman.format.pmsh.Token;
import pman.format.pmsh.Expr;
import pman.pmbash.commands.*;

import electron.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.async.VoidAsyncs;

class PlaylistCommand extends Command {
    override function execute(i:Interpreter, args:Array<Dynamic>, done:VoidCb):Void {
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

                default:
                    done();
            }
        }
    }
}