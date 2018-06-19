package pman.ds;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;
import tannus.TSys as Sys;

import pman.events.EventEmitter;
import pman.GlobalMacros.*;

import haxe.Serializer;
import haxe.Unserializer;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.FunctionTools;
using tannus.ds.AnonTools;
using tannus.macro.MacroTools;

@:genericBuild(pman.ds.ModelBuilder.build())
class ProxyModel<T> {

}
