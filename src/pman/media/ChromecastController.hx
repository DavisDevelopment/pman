package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.events.*;
import tannus.media.Duration;
import tannus.media.TimeRange;
import tannus.media.TimeRanges;
import tannus.math.*;

import electron.Tools.*;

import pman.core.*;
import pman.display.*;
import pman.media.PlaybackCommand;
import pman.async.*;
import pman.time.*;
import pman.Errors.*; 
import pman.tools.chromecast.*;
import pman.tools.chromecast.ExtDevice;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.async.VoidAsyncs;

class ChromecastController extends CastingController<DeviceStatus> {
    /* Constructor Function */
    public function new(d : Device):Void {
        super();

        this.device = d;
        this.status = null;
        this.statusTimer = new Timer(500);
        this.commands = new Array();
    }

/* === Instance Methods === */

    /**
      * initialize [this]
      */
    public function init(done : VoidCb):Void {
        pullStatus(function(?error) {
            if (error != null)
                return done( error );

            trace( status );
            function sloop() {
                sync(function(?err) {
                    sloop();
                });
            }
            sloop();
            done();
        });
    }

    /**
      * each frame
      */
    override function tick():Void {
        statusTimer.tick();
    }

    /**
      * retrieve status
      */
    override function getStatus(done : Cb<DeviceStatus>):Void {
        device.getStatus( done );
    }

    /**
      * get PlayerStatus
      */
    public function getPlayerStatus():PlayerStatus {
        if ( status.exists ) {
            switch ( status.playerState ) {
                case 'IDLE':
                    return PlayerStatus.Empty;
                case 'PAUSED':
                    return PlayerStatus.Paused;
                case 'BUFFERING':
                    return PlayerStatus.Waiting;
                case 'PLAYING':
                    return PlayerStatus.Playing;

                default:
                    throw 'what the fuck';
            }
        }
        else return PlayerStatus.Empty;
    }

    /**
      * pull status
      */
    private function pullStatus(?done : VoidCb):Void {
        getStatus(function(?error, ?stat) {
            if (error != null) {
                if (done != null) {
                    return done( error );
                }
                else {
                    throw error;
                }
            }
            else {
                if (stat != null) {
                    status = stat;
                }
                if (done != null) {
                    done();
                }
            }
        });
    }

    /**
      * synchronize [device] with [this]'s cached state
      */
    private function sync(?done : VoidCb):Void {
        if (done == null) {
            done = (function(?error:Dynamic) {
                if (error != null)
                    throw error;
            });
        }
        runCommands(function(?error) {
            if (error != null) {
                done( error );
            }
            else {
                pullStatus(function(?error) {
                    if (error != null) {
                        done( error );
                    }
                    else {
                        done();
                    }
                });
            }
        });
    }

    /**
      * run [commands]
      */
    private function runCommands(done : VoidCb):Void {
        var a = commands.map( commandAsync );
        commands = new Array();
        a.series( done );
    }

    /**
      * get a VoidAsync from the given command
      */
    private function commandAsync(c : ChromecastCommand):VoidAsync {
        switch ( c ) {
            case Pause:
                return device.pause;
            case Unpause:
                return device.unpause;
            case Volume( time ):
                return device.setVolume.bind(time, _);
            case VolumeMuted( muted ):
                return device.setVolumeMuted.bind(muted, _);
            case Seek( time ):
                return device.seekTo.bind(time, _);
            case Stop:
                return device.stop.bind(_);
        }
    }

    /**
      * add a command to the list
      */
    private function cmd(c : ChromecastCommand):Void {
        var index = c.getIndex();
        commands = commands.filter.fn(_.getIndex() != index);
        commands.push( c );
    }

    public function pause():Void cmd(Pause);
    public function unpause():Void cmd(Unpause);
    public function stop():Void cmd(Stop);

/* === Computed Instance Fields === */

    public var volume(get, set):Float;
    private function get_volume() {
        for (c in commands) switch ( c ) {
            case Volume( vol ):
                return vol;
            default: null;
        }
        return status.ternary(_.volume.level, 1.0);
    }
    private function set_volume(v) {
        if (volume != v)
            cmd(Volume( v ));
        return volume;
    }

    public var muted(get, set):Bool;
    private function get_muted() {
        for (c in commands) switch ( c ) {
            case VolumeMuted( m ):
                return m;
            default: null;
        }
        return status.ternary(_.volume.muted, false);
    }
    private function set_muted(v) {
        if (muted != v)
            cmd(VolumeMuted( v ));
        return muted;
    }

    public var currentTime(get, set):Float;
    private function get_currentTime() {
        for (c in commands) switch ( c ) {
            case Seek(time):
                return time;
            default:
                null;
        }
        return status.ternary(_.currentTime, 0.0);
    }
    private function set_currentTime(v) {
        if (currentTime != v)
            cmd(Seek( v ));
        return currentTime;
    }

    public var duration(get, never):Float;
    private function get_duration():Float return status.ternary(_.media.duration, 0.0);

    public var paused(get, never):Bool;
    private function get_paused():Bool {
        for (c in commands) {
            switch ( c ) {
                case Pause:
                    return true;
                default:
                    null;
            }
        }
        return (status.playerState == 'PAUSED');
    }

/* === Instance Fields === */

    public var device : Device;

    private var status : Maybe<DeviceStatus>;
    private var statusTimer : Timer;
    private var commands : Array<ChromecastCommand>;
}

enum ChromecastCommand {
    Pause;
    Unpause;
    Stop;
    Seek(time : Float);
    Volume(volume : Float);
    VolumeMuted(muted : Bool);
}
