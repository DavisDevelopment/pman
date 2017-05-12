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

import electron.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.async.VoidAsyncs;

class PlayerCommand extends Command {
    override function execute(i:Interpreter, argv:Array<CmdArg>, done:VoidCb):Void {
        var args = argv.map.fn( _.value );
        var action:String = args.shift();
        if (action == null) {
            return done();
        }
        else {
            switch ( action ) {
                case 'play':
                    player.play();

                case 'pause':
                    player.pause();

                case 'next':
                    player.gotoNext();

                case 'previous', 'prev':
                    player.gotoPrevious();

                case 'mute':
                    player.muted = true;

                case 'unmute':
                    player.muted = false;

                case 'volume':
                    var vol = Std.parseFloat(args.shift());
                    vol /= 100;
                    trace( vol );
                    player.volume = vol;

                case 'speed':
                    var speed = Std.parseFloat(args.shift());
                    speed /= 100;
                    player.playbackRate = speed;

                default:
                    done();
            }
        }
    }
}
