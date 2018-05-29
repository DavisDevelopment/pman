package pman.format.time;

import tannus.ds.*;
import tannus.io.*;
//import tannus.media.Duration;
import tannus.async.*;
import tannus.events.*;
import tannus.events.Key;
import tannus.math.Time;
import tannus.math.Percent;

import pman.core.*;
import pman.Globals.*;

import Std.*;
import tannus.math.TMath.*;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;
using tannus.FunctionTools;
using tannus.ds.AnonTools;

enum TimeExpr {
    ETime(time: Time);
    EPercent(percent: Percent);
    
    ERel(op:TimeOp, expr:TimeExpr);
    ERange(min:TimeExpr, max:TimeExpr);
}

enum TimeOp {
    Plus;
    Minus;
    Perc;
}

enum TimeUnit {
    UHour;
    UMin;
    USec;
    UFrame;
}

enum TimeError {
    EInvalidChar(char:Byte, ?posInfos:haxe.PosInfos);
    EUnexpected(what:String, ?posInfos:haxe.PosInfos);
    ECustom(msg:String, ?posInfos:haxe.PosInfos);
}

