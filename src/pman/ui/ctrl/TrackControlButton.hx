package pman.ui.ctrl;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.events.*;
import tannus.graphics.Color;

import gryffin.core.*;
import gryffin.display.*;

import vex.core.Path as VPath;

import pman.core.*;
import pman.display.*;
import pman.display.media.*;
import pman.media.*;
import pman.ui.*;

import tannus.math.TMath.*;
import foundation.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.ds.AnonTools;

class TrackControlButton extends ImagePlayerControlButton {
    /* Constructor Function */
    public function new(c : TrackControlsView):Void {
        super( c.controls );

        tcontrols = c;
    }

/* === Instance Methods === */

    override function calculateGeometry(r : Rectangle):Void {
        super.calculateGeometry( r );

        w = h = (iconSize);
    }

/* === Computed Instance Fields === */

    public var track(get, never):Maybe<Track>;
    private inline function get_track() return player.track;

    public var trackData(get, never):Maybe<TrackData>;
    private inline function get_trackData() return track.ternary(_.data, null);

/* === Instance Fields === */

    public var tcontrols:TrackControlsView;
}
