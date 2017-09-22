package pman.core.exec;

import tannus.io.*;
import tannus.ds.*;
import tannus.async.*;

import Slambda.fn;
import pman.Globals.*;
import haxe.Constraints.Function;

#if !(eval || macro)
import pman.Globals.*;
#end

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.async.VoidAsyncs;

enum MicroTaskSpec {
    MTSync(context:Dynamic, func:Function, ?args:Array<Dynamic>);
    MTAsync(context:Dynamic, func:Function, ?args:Array<Dynamic>);
}
