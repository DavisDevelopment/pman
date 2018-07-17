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
                    done();

                case 'pause':
                    player.pause();
                    done();

                case 'next':
                    player.gotoNext();
                    done();

                case 'previous', 'prev':
                    player.gotoPrevious();
                    done();

                case 'mute':
                    player.muted = true;
                    done();

                case 'unmute':
                    player.muted = false;
                    done();

                case 'volume':
                    var vol = Std.parseFloat(args.shift());
                    vol /= 100;
                    trace( vol );
                    player.volume = vol;
                    done();

                case 'speed':
                    var speed = Std.parseFloat(args.shift());
                    speed /= 100;
                    player.playbackRate = speed;
                    done();

                default:
                    done();
            }
        }
    }
}
