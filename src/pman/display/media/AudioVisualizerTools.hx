package pman.display.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.sys.*;
import tannus.async.*;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.media.MediaObject;
import gryffin.audio.*;
import gryffin.audio.impl.*;

import pman.core.*;
import pman.media.*;
import pman.display.media.AudioVisualizer;

import haxe.extern.EitherType;
import haxe.Constraints.Function;

import edis.Globals.*;
import pman.Globals.*;
import Std.*;
import tannus.math.TMath.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.html.JSTools;
using tannus.async.Asyncs;

class AudioVisualizerTools {

}

class EAudioDataTools {
    public static inline function toByteAudioData(e:EAudioData, safe:Bool=false, coerce:Bool=false):AudioData<Int> {
        return switch e {
            case EUInt8(d): d;
            case _: throw 'TypeError: Not byte data $e';
        };
    }

    public static inline function toFloatAudioData(e:EAudioData, safe:Bool=false, coerce:Bool=false):AudioData<Float> {
        return switch e {
            case EFloat32(d): d;
            case _: throw 'TypeError: Not float data $e';
        }
    }

    public static function toAudioData<T:Float>(e:EAudioData, ?type:AudioDataNumType, safe:Bool=false, coerce:Bool=false):AudioData<T> {
        return switch e {
            case EUInt8(d): cast d;
            case EFloat32(d): cast d;
            case _: throw 'Wtf';
        }
    }
}

class AVDataContainerTools {
    public static inline function isStereo(con:AVDataContainer):Bool {
        return (con:Chan<AVDataValue>).match(Duo(_,_)|Trio(_,_,_));
    }

    public static inline function isMono(con: AVDataContainer):Bool {
        return (con:Chan<AVDataValue>).match(Mono(_));
    }

    public static inline function hasMono(con: AVDataContainer):Bool {
        return (con:Chan<AVDataValue>).match(Mono(_)|Trio(_,_,_));
    }

    public static inline function getDataAll(con:AVDataContainer):Array<Array<EAudioData>> {
        return ChanTools.arrayMap2(con, e -> e);
    }

    public static inline function getDataAllAs<TOut>(con:AVDataContainer, f:EAudioData->TOut):Array<Array<TOut>> {
        return ChanTools.arrayMap2(con, e -> f(e));
    }

    public static inline function toAudioData<T:Float>(con: AVDataContainer):AudioData<T> {
        return switch con {
            case Mono(x): AVDataValueTools.getOnlyData(x);
            case _: throw 'Nope';
        };
    }

    public static inline function toDataPair<L:Float, R:Float>(con:AVDataContainer):Pair<AudioData<L>, AudioData<R>> {
        return switch con {
            case Duo(l, r)|Trio(l,_,r): new Pair(ed1(l), ed1(r));
            case _: throw 'Nope';
        };
    }

    public static inline function getLeftChannelData(con:AVDataContainer):EAudioData {
        return switch con {
            case Duo(l, _)|Trio(l,_,_): AVDataValueTools.getSingleValue(l);
            case _: throw 'Error: Left Channel unavailable';
        };
    }

    public static inline function getRightChannelData(con: AVDataContainer):EAudioData {
        return switch con {
            case Duo(_, r)|Trio(_,_,r): AVDataValueTools.getSingleValue(r);
            case _: throw 'Error: Right channel unavailable';
        };
    }

    public static inline function getStereo(con: AVDataContainer):Array<EAudioData> {
        return [getLeftChannelData(con), getRightChannelData(con)];
    }

    static inline function ed1<T:Float>(x: AVDataValue):AudioData<T> return AVDataValueTools.getOnlyData( x );
}

class AVDataValueTools {
    public static inline function extract<T:Float>(v:AVDataValue, ?type:AudioDataNumType, ?safe:Bool, ?coerce:Bool):Array<AudioData<T>> {
        return ChanTools.arrayMap(v, e -> EAudioDataTools.toAudioData(e, type, safe, coerce));
    }

    public static inline function getDatas<T:Float>(v:AVDataValue, n:Int, ?type:AudioDataNumType, ?safe:Bool, ?coerce:Bool):Array<AudioData<T>> {
        return getValues(v, n).map(e -> EAudioDataTools.toAudioData(e, type, safe, coerce));
    }

    public static inline function getOnlyData<T:Float>(v:AVDataValue, ?type:AudioDataNumType, ?safe:Bool, ?coerce:Bool):AudioData<T> {
        return EAudioDataTools.toAudioData(getSingleValue(v), type, safe, coerce);
    }

    public static inline function getSingleValue(v:AVDataValue, combine:Bool=false):EAudioData {
        return switch v {
            case Mono(x): x;
            case Trio(_,x,_): x;
            case Duo(x, y):
                if ( combine ) {
                    EAudioData.createByName(
                        x.getName(),
                        [
                        AudioDataTools.avgWith(
                            EAudioDataTools.toAudioData(x),
                            EAudioDataTools.toAudioData(y)
                        )
                        ]
                    );
                }
                else
                    x;
            case _:
                throw 'Wtf($v)';
        }
    }

    public static inline function getMono(v: AVDataValue):Array<EAudioData> {
        return [getSingleValue(v)];
    }

    public static inline function getDuo(v: AVDataValue):Array<EAudioData> {
        return switch v {
            case Mono(x): [x, x];
            case Duo(x, y)|Trio(x,_,y): [x, y];
            default:
                throw 'Wtf($v)';
        }
    }

    public static inline function getTrio(v: AVDataValue):Array<EAudioData> {
        return switch v {
            case Mono(x): [x,x,x];
            case Duo(x,y): [x,x,y];
            case Trio(x,y,z): [x,y,z];
            default:
                throw 'Wtf($v)';
        }
    }

    public static inline function getValues(v:AVDataValue, n:Int):Array<EAudioData> {
        return switch n {
            case 1: getMono(v);
            case 2: getDuo(v);
            case 3: getTrio(v);
            case _:
                throw 'resolving $n values is unsupported';
        }
    }
}

class ChanTools {
    public static inline function apply<T>(c:Chan<T>, f:T->Void) {
        switch c {
            case Mono(x): 
                f(x);
            case Duo(x,y):
                f(x);
                f(y);
            case Trio(x,y,z):
                f(x);
                f(y);
                f(z);
        }
    }

    public static inline function apply2<T>(c:Chan<Chan<T>>, f:T->Void) {
        apply(c, (c2 -> apply(c2, f)));
    }

    public static inline function arrayMap<TIn, TOut>(c:Chan<TIn>, f:TIn->TOut):Array<TOut> {
        return switch c {
            case Mono(x): [f(x)];
            case Duo(x, y): [f(x), f(y)];
            case Trio(x,y,z): [f(x),f(y),f(z)];
        };
    }
    public static inline function arrayMap2<TIn,TOut>(c:Chan<Chan<TIn>>, f:TIn->TOut):Array<Array<TOut>> {
        return arrayMap(c, (c2 -> arrayMap(c2, f)));
    }

    public static inline function map<TIn, TOut>(c:Chan<TIn>, f:TIn->TOut):Chan<TOut> {
        return switch c {
            case Mono(x): Mono(f(x));
            case Duo(x, y): Duo(f(x), f(y));
            case Trio(x,y,z): Trio(f(x),f(y),f(z));
        };
    }

    public static inline function values<T>(c: Chan<T>):Array<T> {
        return untyped c.getParameters();
    }
}

class AudioDataTools {
    public static inline function avgWith<T:Float>(a:AudioData<T>, b:AudioData<T>, ?dest:AudioData<T>, ?f2i:Float->Int):AudioData<T> {
        var intMode:Bool = (a is ByteAudioData);
        if (intMode && f2i == null)
            f2i = TMath.round;
        if (dest == null)
            dest = createEmptyClone( a );
        for (i in 0...a.length) {
            dest[i] = cast (intMode ? f2i((a[i] + b[i]) / 2) : (a[i] + b[i]) / 2);
        }
        return dest;
    }

    public static function average<T:Float>(datas:Array<AudioData<T>>, ?dest:AudioData<T>, ?f2i:Float->Int):AudioData<T> {
        var intMode:Bool = false;
        if (datas[0] == null)
            return null;
        if ((datas[0] is ByteAudioData))
            intMode = true;
        if (intMode && f2i == null)
            f2i = TMath.round;
        if (dest == null)
            dest = createEmptyClone(datas[0]);
        var getters = [for (d in datas) (i -> d[i])];
        inline function gets(i: Int)
            return [for (get in getters) get(i)];

        for (i in 0...dest.length) {
            var avg = gets( i ).average();
            if ( intMode ) {
                avg = f2i( avg );
            }
            dest[i] = untyped avg;
        }

        return dest;
    }

    public static inline function createEmptyClone<T:Float>(d: AudioData<T>):AudioData<T> {
        if ((d is ByteAudioData))
            return cast AudioData.allocByte( d.length );
        else if ((d is Float32AudioData))
            return cast AudioData.allocFloat( d.length );
        else
            throw 'TypeError: Unrecognized AudioData type';
    }

    public static inline function getNumType<T:Float>(d: AudioData<T>):AudioDataNumType {
        return 
            if (is(d, ByteAudioData))
                ADNT_UInt8;
            else if (is(d, Float32AudioData))
                ADNT_Float32;
            else
                throw 'TypeError: Cannot resolve numerical type from ${Type.getClassName(Type.getClass(cast d))}';
    }
}
