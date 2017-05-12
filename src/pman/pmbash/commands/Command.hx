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

class Command extends Cmd {
/* === Computed Instance Fields === */

    public var main(get, never):BPlayerMain;
    private inline function get_main():BPlayerMain return BPlayerMain.instance;

    public var player(get, never):Player;
    private inline function get_player() return main.player;
}
