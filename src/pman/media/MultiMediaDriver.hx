package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.events.*;
import tannus.media.Duration;
import tannus.media.TimeRange;
import tannus.media.TimeRanges;
import tannus.math.*;
import tannus.async.*;

import gryffin.core.*;
import gryffin.display.*;

import pman.display.*;
import pman.media.PlaybackCommand;
import pman.ds.FixedLengthArray;

import edis.Globals.*;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.async.Asyncs;
using tannus.FunctionTools;
using tannus.ds.IteratorTools;
using tannus.math.TMath;

class MultiMediaDriver extends MediaDriver {
    /* Constructor Function */
    public function new(drivers: Iterable<MediaDriver>):Void {
        super();

        srcJoin = CommaSeparated;
        durJoin = DjtAverage;
        timeJoin = TjtProportional;

        _fi = 0;

        var dl = drivers.array();
        this.drivers = FixedLengthArray.alloc( dl.length );
        for (i in 0...dl.length) {
            this.drivers[i] = dl[i];
        }

        lengthCoefficients = new FixedLengthArray(dl.length, 1.0);
    }

/* === Instance Methods === */

    public function setFocusedIndex(i: Int):MediaDriver {
        if (drivers[i] == null) {
            throw 'IndexOutOfBoundsError: No MediaDriver at offset($i)';
        }
        return drivers[_fi = i];
    }

    public inline function getFocusedIndex():Int return _fi;

    override function tick():Void {
        //TODO
    }

    override function play() apply((i, d) -> d.play());
    override function pause() apply((i, d) -> d.pause());
    override function togglePlayback() apply((i, d) -> d.togglePlayback());
    override function stop() apply((i, d) -> d.stop());

    override function getSource():String {
        if ( __singular ) {
            return fd.getSource();
        }
        else {
            var srcs = veach.fn(_.getSource());
            return (switch srcJoin {
                case CommaSeparated: srcs.map(s -> s.urlEncode()).join(',');
                case PmanUri: ('pman://media.multi/' + srcs.map.fn(_.urlEncode()).join('&'));
                case Custom(f): f( srcs );
            });
        }
    }

    override function getDurationTime():Float {
        if (__singular || durJoin.match(DjtFocused)) {
            return fd.getDurationTime();
        }
        else {
            var lens = veach.fn(_.getDurationTime());
            switch ( durJoin ) {
                case DjtMin:
                    return lens.min(identity);
                case DjtMax:
                    return lens.max(identity);
                case DjtAverage:
                    return lens.average();
                case DjtSum:
                    return lens.sum();
                default:
                    throw 'Unexpected $durJoin';
            }
        }
    }

    override function getCurrentTime():Float {
        var len:Float = getDurationTime();
        if ( __singular ) {
            if ( __sequential ) {
                return (_time_offset + fd.getCurrentTime());
            }
            
            return fd.getCurrentTime();
        }
        else {
            return len * (fd.getCurrentTime() / fd.getDurationTime());
        }
    }

    override function getPlaybackRate():Float {
        return _rate;
    }

    override function setVolume(v: Float):Void {
        _volume = v;
        __sync_volume();
    }

    override function setCurrentTime(time: Float):Void {
        var len:Float = getDurationTime();
        apply(function(i, d) {
            d.setCurrentTime((time / len) * d.getDurationTime());
        });
    }

    override function setPlaybackRate(rate: Float):Void {
        _rate = rate;
        __sync_rate();
    }

    override function setMuted(muted: Bool):Void {
        _muted = muted;
        __sync_muted();
    }

    override function getEnded():Bool {
        if ( __singular ) {
            return fd.getEnded();
        }
        else {
            return drivers.all(d -> d.getEnded());
        }
    }

    override function dispose(done: VoidCb):Void {
        vbatch(function(add, exec) {
            each(function(i, d) {
                add( d.dispose );
            });
            add(function(next) {
                drivers = null;
                lengthCoefficients = null;

                next();
            });
        }, done);
    }

    var _sigLoad:Null<VoidSignal> = null;
    override function getLoadSignal():VoidSignal {
        if (_sigLoad == null) {
            _sigLoad = new VoidSignal();
            vbatch(function(add, exec) {
                for (sig in vsigs(fn(_.getLoadSignal()))) {
                    add(function(next) {
                        sig.once(function() {
                            next();
                        });
                    });
                }
                exec();
            }, function(?error) {
                if (error != null) {
                    report( error );
                }
                else {
                    _sigLoad.fire();
                }
            })
        }
        return _sigLoad;
    }

    var _sigEnded:Null<VoidSignal> = null;
    override function getEndedSignal():VoidSignal {
        if (_sigEnded == null) {
            _sigEnded = new VoidSignal();
            vbatch(function(add, exec) {
                for (sig in vsigs(fn(_.getEndedSignal()))) {
                    add(function(next) {
                        sig.once(function() {
                            next();
                        });
                    });
                }
                exec();
            }, function(?error) {
                if (error != null) {
                    report( error );
                }
                else {
                    _sigEnded.fire();
                }
            })
        }
        return _sigEnded;
    }

    var _sigCanPlay:Null<VoidSignal> = null;
    override function getCanPlaySignal():VoidSignal {
        if (_sigCanPlay == null) {
            _sigCanPlay = new VoidSignal();
            vbatch(function(add, exec) {
                for (sig in vsigs(fn(_.getCanPlaySignal()))) {
                    add(function(next) {
                        sig.once(function() {
                            next();
                        });
                    });
                }
                exec();
            }, function(?error) {
                if (error != null) {
                    report( error );
                }
                else {
                    _sigCanPlay.fire();
                }
            })
        }
        return _sigCanPlay;
    }

    var _sigLoadedMetadata:Null<VoidSignal> = null;
    override function getLoadedMetadataSignal():VoidSignal {
        if (_sigLoadedMetadata == null) {
            _sigLoadedMetadata = new VoidSignal();
            vbatch(function(add, exec) {
                for (sig in vsigs(fn(_.getLoadedMetadataSignal()))) {
                    add(function(next) {
                        sig.once(function() {
                            next();
                        });
                    });
                }
                exec();
            }, function(?error) {
                if (error != null) {
                    report( error );
                }
                else {
                    _sigLoadedMetadata.fire();
                }
            })
        }
        return _sigLoadedMetadata;
    }

    var _sigEnded:Null<VoidSignal> = null;
    override function getEndedSignal():VoidSignal {
        if (_sigEnded == null) {
            _sigEnded = new VoidSignal();
            vbatch(function(add, exec) {
                for (sig in vsigs(fn(_.getEndedSignal()))) {
                    add(function(next) {
                        sig.once(function() {
                            next();
                        });
                    });
                }
                exec();
            }, function(?error) {
                if (error != null) {
                    report( error );
                }
                else {
                    _sigEnded.fire();
                }
            })
        }
        return _sigEnded;
    }

    private function sigs<T>(sig:MediaDriver->Signal<T>):Array<Signal<T>> {
        if ( __singular ) {
            return [sig(fd)];
        }
        else {
            return drivers.array().map( sig )
        }
    }
    private function vsigs(sig:MediaDriver->VoidSignal):Array<VoidSignal> {
        if ( __singular ) {
            return [sig(fd)];
        }
        else {
            return drivers.array().map( sig )
        }
    }
    private function sigapply<T>(sig:MediaDriver->Signal<T>, f:Signal<T>->Void):Void {
        apply(function(i, d) {
            sig( d ).passTo( f );
        });
    }
    private function vsigapply(sig:MediaDriver->VoidSignal, f:VoidSignal->Void):Void {
        apply((i, d) -> sig(d).passTo(f));
    }

    private function timeCoefficients(adjusted:Bool=false):Array<Float> {
        var len:Float = getDurationTime();
        return veach(function(i, d) {
            var tc = (d.getCurrentTime() / d.getDurationTime());
            if ( adjusted ) {
                tc = adjustTime(i, tc);
            }
            return tc;
        }).map.fn(_ * len);
    }

    private inline function adjustTime(index:Int, time:Float):Float {
        return (lengthCoefficients[index] * time);
    }

    public function recalcLengthCoefficients():Void {
        var len:Float = getDurationTime();
        each(function(i, d) {
            lengthCoefficients[i] = mdlc(d, len);
        });
    }

    private function __sync_volume() {
        each(function(i, d) {
            d.setVolume( _volume );
        });
    }

    private function __sync_muted() {
        if ( __audioFromFocused ) {
            each((i,d) -> d.setMuted(true));
            fd.setMuted( _muted );
        }
        else {
            apply((i, d) -> d.setMuted( _muted ));
        }
    }

    private function __sync_rate() {
        if ( __singular ) {
            fd.setPlaybackRate( _rate );
        }
        else {
            var len = getDurationTime();
            each(function(i, d) {
                d.setPlaybackRate(lengthCoefficients[i] * _rate);
            });
        }
    }

    private function __sync() {
        var d:MediaDriver;
        var len:Float = getDurationTime();
        for (i in 0...drivers.length) {
            d = drivers[i];
            if (__singular && i != _fi) {
                if ( __audioFromFocused ) {
                    d.setMuted( true );
                }
                continue;
            }
            else if ( __singular ) {
                d.setPlaybackRate( _rate );
                d.setMuted( _muted );
            }
            else if ( __synchronized ) {
                d.setPlaybackRate(lengthCoefficients[i] * _rate);
                d.setMuted( _muted );
            }

            d.setVolume( _volume );
        }
    }

    private function apply(f: Int->MediaDriver->Void):Void {
        if ( __singular ) {
            f(_fi, drivers[_fi]);
        }
        else {
            each( f );
        }
    }

    private function reduce<TOut>(f:TOut->Int->MediaDriver->TOut, acc:TOut):TOut {
        each(function(i, d) {
            acc = f(acc, i, d);
        });
        return acc;
    }

    private function veach<TOut>(f:Int->MediaDriver->TOut):Array<TOut> {
        var a:Array<TOut> = new Array();
        each(function(i, d) {
            a.push(f(i, d));
        });
        return a;
    }

    private function each(f: Int->MediaDriver->Void):Void {
        for (index in 0...mediaCount) {
            f(index, drivers.get(index));
        }
    }

    private function ieach<TOut>(f:MediaDriver->TOut):Iterator<TOut> {
        return drivers.iterator().map( f );
    }

    private static inline function mdlc(d:MediaDriver, dlen:Float):Float {
        return lc(d.getDurationTime(), dlen);
    }

    private static inline function lc(len:Float, dlen:Float):Float {
        return (len / dlen);
    }

/* === Computed Instance Fields === */

    public var mediaCount(get, never): Int;
    private inline function get_mediaCount() return drivers.length;

    private var fd(get, never): MediaDriver;
    private inline function get_fd() return drivers[_fi];

/* === Instance Fields === */

    public var srcJoin: SourceJoinType;
    public var durJoin: DurationJoinType;
    public var timeJoin: TimeJoinType;

    private var drivers: FixedLengthArray<MediaDriver>;
    private var lengthCoefficients: FixedLengthArray<Float>;

    /* the index of the 'focused' driver (what 'focused' means will vary with other configs) */
    private var _fi: Int;

    /* playback rate */
    private var _rate: Float;
    private var _muted: Bool;
    private var _volume: Float;
    private var _time_offset: Float;

/* === Configuration Fields === */

    /* whether [this] only controls one driver at a time, determined by [_fi] */
    private var __singular: Bool = false;

    /* whether to ensure that all media is synchronized */
    private var __synchronized: Bool = true;

    /* whether to mute all non-focused drivers */
    private var __audioFromFocused: Bool = true;

    /* whether items will be mounted one after another */
    private var __sequential: Bool = false;
}

enum SourceJoinType {
    CommaSeparated;
    PmanUri;
    Custom(f: Array<String> -> String);
}

enum TimeResolveType {
    Normal;
}

enum DurationJoinType {
    DjtMin;
    DjtMax;
    DjtAverage;
    DjtSum;
    DjtFocused;
}

enum TimeJoinType {
    TjtMin;
    TjtMax;
    TjtAverage;
    TjtSum;
    TjtProportional;
    TjtFocused;
}
