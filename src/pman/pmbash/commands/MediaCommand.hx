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

/**
  command for dealing with the current media
 **/
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
                    cmdRename(args, done);

                case 'add':
                    action = args.shift();
                    if (action.empty()) {
                        done('Error: Missing argument');
                    }
                    else {
                        switch action {
                            case 'mark', 'bookmark', 'bm':
                                //TODO
                                done();

                            case 'actor', 'actress', 'cast', 'star', 'pornstar':
                                //TODO
                                done();

                            case 'tag', 'category':
                                //TODO
                                done();

                            case _:
                                done('Error: Unsupported argument "$action"');
                        }
                    }

                case 'mark'|'marks'|'bookmark'|'bookmarks':
                    action = args.shift();
                    if (action.empty()) {
                        done('Error: Missing argument');
                    }
                    else {
                        //TODO
                        done();
                    }

                case 'actor'|'actress'|'cast'|'pornstar'|'actors'|'actresses'|'pornstars':
                    //TODO
                    done();

                default:
                    done();
            }
        }
    }

    function cmdRename(args:Array<Dynamic>, done:VoidCb):Void {
        if (!args.empty()) {
            var curPath = player.track.getFsPath();
            var newName:String = args.shift();
            var newPath:Path = (curPath.directory.plusString( newName )).normalize();
            _renameTrack(newPath, done);
        }
        else {
            _renameTrack(null, done);
        }
    }

    function _renameTrack(newPath:Null<Path>, done:VoidCb):Void {
        var task = new TrackRename(player.track, database.media, newPath);
        task.run( done );
    }
}
