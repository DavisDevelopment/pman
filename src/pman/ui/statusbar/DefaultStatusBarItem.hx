package pman.ui.statusbar;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.events.*;
import tannus.graphics.Color;

import gryffin.core.*;
import gryffin.display.*;

import pman.core.*;
import pman.media.*;
import pman.display.*;
import pman.display.media.*;
import pman.ui.ctrl.*;

import tannus.math.TMath.*;
import gryffin.Tools.*;

import motion.Actuate;
import motion.easing.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class DefaultStatusBarItem extends StatusBarItem {
    /* Constructor Function */
    public function new():Void {
        super();

        duration = -1;
        tb = new TextBox();
        tb.fontFamily = 'Ubuntu';
        tb.fontSizeUnit = 'px';
        tb.fontSize = 10;
        tb.color = new Color(255, 255, 255);
    }

/* === Instance Methods === */

    /**
      * render [this]
      */
    override function render(stage:Stage, c:Ctx):Void {
        var tbr = new Rect(0.0, 0.0, tb.width, tb.height);
        tbr.centerY = floor( centerY );
        tbr.x = 0;

        c.drawComponent(tb, 0, 0, tb.width, tb.height, tbr.x, tbr.y, tbr.w, tbr.h);
    }

    /**
      * update [this]
      */
    override function update(stage : Stage):Void {
        super.update( stage );

        // reset some of the content state to default
        resetContent();

        // shorthand reference to [player.track]
        var t:Null<Track> = player.track;

        // whether [this]'s displayed content is textual
        var isText:Bool = true;

        //TODO determine what type of content is to be displayed...

        // if content is textual
        if ( isText ) {
            // the 'old' textual content of the text box
            var oldText:String = tb.text;

            // the 'old' area of the text box
            var oa:Area<Float> = new Area(tb.width, tb.height);

            // if there is no track, render blank string
            if (t == null) {
                tb.text = '';
            }
            else {
                // based on MediaSource type, display either...
                switch ( t.source ) {
                    // a FileSystem Path for local media
                    case MediaSource.MSLocalPath( path ):
                        tb.text = path;

                    // or a URI for remote media
                    case MediaSource.MSUrl( url ):
                        tb.text = url;
                }

                // if [t] has its metadata loaded, and it's favorited
                if (t.data != null && t.data.starred) {
                    // prepend a denotation to the text
                    tb.text = (' (favorited) ' + tb.text);
                }
            }

            // the 'new' Area of the text box
            var na:Area<Float> = new Area(tb.width, tb.height);

            // if the text's dimensions have changed
            if (na.nequals( oa )) {
                // set content rect
                ch = na.height;
                cw = max(w, na.width);
            }
        }
    }

    /**
      * calculate [this]'s geometry
      */
    override function calculateGeometry(r: Rect<Float>):Void {
        super.calculateGeometry( r );
    }

    /**
      *
      */
    private function resetContent():Void {
        ch = 0.0;
        cw = 0.0;

        atb = new Array();
    }

/* === Instance Fields === */

    // single TextBox for rendering simple text information
    private var tb : TextBox;

    // array of TextBoxes, for rendering dynamic hunks of multi-styling text
    private var atb: Array<TextBox>;
}
