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
      * add a command to the list
      */
    private function cmd(c : ChromecastCommand):Void {
        var index = c.getIndex();
        commands = commands.filter.fn(_.getIndex() != index);
        commands.push( c );
    }

/* === Computed Instance Fields === */

    public var volume(get, set):Float;
    private inline function get_volume() return status.ternary(_.volume.level, 1.0);
    private function set_volume(v) {
        cmd(Volume( v ));
        return volume;
    }

    public var muted(get, set):Bool;
    private function get_muted() return status.ternary(_.volume.muted, false);
    private function set_muted(v) {
        cmd(VolumeMuted( v ));
        return muted;
    }

    public var currentTime(get, set):Float;
    private function get_currentTime() return status.ternary(_.currentTime, 0.0);
    private function set_currentTime(v) {
        cmd(Seek( v ));
        return currentTime;
    }

    public var duration(get, never):Float;
    private function get_duration():Float return status.ternary(_.media.duration, 0.0);

    public var paused(get, never):Bool;
    private function get_paused():Bool return (status.playerState == 'PAUSED');

/* === Instance Fields === */

    public var device : Device;

    private var status : Maybe<DeviceStatus>;
    private var statusTimer : Timer;
    private var commands : Array<ChromecastCommand>;
}

enum ChromecastCommand {
    Pause;
    Unpause;
    Seek(time : Float);
    Volume(volume : Float);
    VolumeMuted(muted : Bool);
}
