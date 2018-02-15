package pman.pmbash.commands;

import tannus.io.*;
import tannus.ds.*;
import tannus.async.*;
import tannus.math.*;
import tannus.sys.Path;
import tannus.TSys as Sys;

import pman.core.*;
import pman.media.*;
import pman.bg.media.*;
import pman.async.tasks.*;
import pman.format.pmsh.*;
import pman.format.pmsh.Token;
import pman.format.pmsh.Expr;
import pman.format.pmsh.Cmd;
import pman.pmbash.commands.*;

import Slambda.fn;
import tannus.math.TMath.*;
import edis.Globals.*;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.FunctionTools;
using tannus.async.Asyncs;

class MediaCommand extends Command {
    /**
      * execute [this] command
      */
    override function execute(i:Interpreter, argv:Array<CmdArg>, done:VoidCb):Void {
        var args:Array<Dynamic> = argv.map.fn( _.value );
        var action:Null<String> = args.shift();
        if (action == null) {
            return done();
        }
        else {
            switch ( action ) {
                case 'star', 'favorite':
                    player.track.star( done );

                case 'unstar', 'unfavorite':
                    player.track.unstar( done );

                case 'rename':
                    if (!args.empty()) {
                        var curPath:Null<Path> = player.track.getFsPath();
                        if (curPath == null) {
                            return done('PMBashError: Cannot rename a non-local media');
                        }
                        var newName:String = args.shift();
                        var newPath:Path = (curPath.directory.plusString( newName )).normalize();
                        var task = new TrackRename(player.track, database.media, newPath);
                        task.run( done );
                    }
                    else {
                        return done('PMBashError: Missing argument [newPath]');
                    }

                case 'add':
                    //TODO

                default:
                    done();
            }
        }
    }
}
