package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.events.*;
import tannus.media.Duration;
import tannus.media.TimeRange;
import tannus.media.TimeRanges;
import tannus.math.*;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.media.MediaObject;

import pman.core.*;
import pman.display.*;
import pman.media.PlaybackCommand;
import pman.Errors.*; 

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

@:access( pman.media.ChromecastController )
class ChromecastMediaDriver extends MediaDriver {
    private var cc : ChromecastController;
    public function new(cc : ChromecastController):Void {
        super();

        this.cc = cc;
    }

    override function play() cc.unpause();
    override function pause() cc.pause();
    override function togglePlayback() (cc.paused?play:pause)();
    override function stop() cc.stop();
    override function getSource() {
        return cc.status.media.contentId;
    }
    override function getDurationTime() return cc.duration;
    override function getCurrentTime() return cc.currentTime;
    override function getPlaybackRate() return 1.0;
    override function getPaused() return cc.paused;
    override function getMuted() return cc.muted;
    override function getVolume() return cc.volume;
    override function getEnded() return false;
    override function setSource(src:String) return ;
    override function setCurrentTime(time:Float) cc.currentTime = time;
    override function setPlaybackRate(speed:Float) return ;
    override function setVolume(vol:Float) cc.volume = vol;
    override function setMuted(m:Bool) cc.muted = m;
}
