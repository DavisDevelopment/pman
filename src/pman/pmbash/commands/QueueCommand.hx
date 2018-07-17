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
import pman.pmbash.args.*;

import Slambda.fn;
import tannus.math.TMath.*;
import edis.Globals.*;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;
using tannus.async.Asyncs;
using pman.bg.PathTools;
using pman.media.MediaTools;

class QueueCommand extends HierCommand {
    override function _build_() {
        cmd(this, 'shuffle', cmdShuffle);
        cmd(this, 'clear', cmdClearQueue);
    }

    function cmdClearQueue(argv:Array<CmdArg>, done:VoidCb) {
        player.clearPlaylist();
        done();
    }

    function cmdShuffle(argv:Array<CmdArg>, done:VoidCb) {
        player.shufflePlaylist();
        done();
    }

    inline function cmd(self:HierCommand, name, f) self.subCmd(name, onlyArgs(f));
    inline function pcmd(self:HierCommand, name, f) {
        self.createSubCommand(name, {}, function(c) {
            c.pythonicMain( f );
        });
    }
}
