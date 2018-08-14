package pman.pmbash.commands;

import tannus.io.*;
import tannus.ds.*;
import tannus.async.*;
import tannus.math.*;
import tannus.TSys as Sys;

import pman.core.*;
import pman.async.*;
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

class BookmarkCommand extends Command {
    /**
      * execute [this] command
      */
    override function execute(i:Interpreter, argv:Array<CmdArg>, done:VoidCb):Void {
        var args:Array<Dynamic> = argv.map.fn( _.value );
        var action:Null<String> = args.shift();
        if (action == null) {
            player.addBookmark( done );
        }
        else {
            switch ( action ) {
                case 'add':
                    var name:Null<String> = args.shift();
                    var time:Null<Float> = args.shift();
                    if (time == null) time = player.currentTime;
                    player.track.addMark(new pman.bg.media.Mark(Named(name), time));
                    player.track.data.save( done );

                case 'rename':
                    player.message('TODO: pmbash bookmark renaming');
                    done();

                default:
                    done();
            }
        }
    }
}
