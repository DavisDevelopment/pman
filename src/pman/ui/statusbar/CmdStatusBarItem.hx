package pman.ui.statusbar;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.events.*;
import tannus.events.Key;
import tannus.graphics.Color;

import foundation.TextInput;

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

class CmdStatusBarItem extends StatusBarItem {
    /* Constructor Function */
    public function new():Void {
        super();

        duration = -1;
        tb = new TextBox();
        tb.fontFamily = 'Ubuntu';
        tb.fontSizeUnit = 'px';
        tb.fontSize = 15;
        tb.color = new Color(255, 255, 255);

        ti = new TextInput();
        ti.el.attr('type', 'hidden');
        ti.on('keydown', _tiKeyDown);
        lineEvent = new Signal();
    }

/* === Instance Methods === */

    /**
      * render [this]
      */
    override function render(stage:Stage, c:Ctx):Void {
        var tbr = new Rectangle(0, 0, tb.width, tb.height);
        tbr.centerY = centerY;
        tbr.x = 0;

        c.drawComponent(tb, 0, 0, tb.width, tb.height, tbr.x, tbr.y, tbr.w, tbr.h);
    }

    /**
      * update [this]
      */
    override function update(stage : Stage):Void {
        super.update( stage );

        var oldText = tb.text;
        tb.text = ti.getValue();

        if (oldText != tb.text) {
            tb.autoScale(null, rect.h, 0.5);
        }
    }

    /**
      * delete [this]
      */
    override function delete():Void {
        super.delete();
        ti.destroy();
    }

    /**
      * 'open' [this]
      */
    public function open():Void {
        if (!ti.childOf('body')) {
            ti.appendTo('body');
        }
        defer(function() {
            defer( ti.focus );
        });
    }

    /**
      * 'close' [this]
      */
    public function close():Void {
        delete();
    }

    /**
      * handle keyboard events
      */
    private function _tiKeyDown(event : KeyboardEvent):Void {
        event.stopPropogation();
        switch ( event.key ) {
            case Enter:
                event.cancel();
                submit();

            case Esc:
                event.cancel();
                close();

            default:
                return ;
        }
    }

    /**
      * fires the lineEvent
      */
    private function submit():Void {
        var line:Null<String> = ti.getValue();
        if (line == null) {
            return ;
        }
        else {
            line = line.trim();
            if (line.length == 0) {
                return ;
            }
            lineEvent.call( line );
        }
    }

    /**
      * wait for the next line
      */
    public function getLine(f : String->Void):Void {
        lineEvent.once( f );
    }

/* === Instance Fields === */

    public var lineEvent : Signal<String>;

    private var tb : TextBox;
    private var ti : TextInput;
}
