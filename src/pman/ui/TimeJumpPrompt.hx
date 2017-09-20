package pman.ui;

import foundation.*;

import tannus.ds.*;
import tannus.io.*;
import tannus.media.Duration;
import tannus.async.*;
import tannus.html.Element;
import tannus.events.*;
import tannus.events.Key;

import pman.core.*;

import Std.*;
import tannus.math.TMath.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;

class TimeJumpPrompt extends PromptBox {
    /* Constructor Function */
    public function new():Void {
        super();

        el['id'] = 'jump';
        el.data('model', this);
    }

/* === Instance Methods === */

    public function setTime(time : Duration):Void {
        value = time.toString();
    }

    private function sepIndices(edges:Bool=false):Array<Int> {
        var s = value, char:String;
        var indices = [0];
        for (index in 0...s.length) {
            char = s.charAt( index );
            if (char == ':') {
                indices = indices.concat([(index - 1), (index + 1)]);
            }
        }
        indices.push(s.length - 1);
        return indices;
    }

    public function segments():Array<SegmentBound> {
        var results = [];
        var sil = new Stack(sepIndices( true ));
        while (!sil.empty) {
            results.push({
                x: sil.pop(),
                y: sil.pop()
            });
        }
        return results;
    }

    public function hiliteSegmentByIndex(i:Int=0, ?segs:Array<SegmentBound>):Void {
        if (segs == null)
            segs = segments();
        var bounds = segs[i];
        if (bounds != null) {
            hiliteSegment( bounds );
        }
    }

    public function hiliteSegment(?segment : SegmentBound):Void {
        if (segment == null)
            segment = segments()[0];
        selectRange(segment.x, segment.y);
    }

    public function getCaretSegment():Int {
        var segs = segments();
        var cursor = caret();
        for (index in 0...segs.length) {
            if (cursor > segs[index].x && cursor < segs[index].y) {
                return index;
            }
            else continue;
        }
        return -1;
    }

    public function getSegmentText(i:Int, ?segs:Array<{x:Int,y:Int}>):Maybe<String> {
        if (segs == null)
            segs = segments();
        var txt = value, seg = segs[i];
        if (seg != null) {
            return txt.substring(seg.x, seg.y);
        }
        else return null;
    }

    public function setSegmentText(index:Int, segmentText:String):String {
        var txt = value, segs = segments(), seg = segs[index];
        var before:Null<Array<String>> = null, after:Null<Array<String>> = null;
        if (index > 1) {
            before = [for (i in 0...index) getSegmentText(i, segs)];
        }
        if (index < (segs.length - 1)) {
            after = [for (i in (index + 1)...(segs.length - 1)) getSegmentText(i, segs)];
        }
        var resultText:String = '';
        if (before != null) {
            resultText += before.join('');
        }
        resultText += segmentText;
        if (after != null) {
            resultText += after.join('');
        }
        return (value = resultText);
    }

    /**
      * handle events
      */
    override function __listen():Void {
        super.__listen();

        input.on('focus', function(event) {
            //TODO
            trace('focus');
        });

        input.on('focusin', function(event) {
            //TODO
            trace('focusin');
        });

        input.on('blur', function(event) {
            //TODO
            trace('blur');
        });
    }

    /**
      * handle keydown events
      */
    override function keyup(event : KeyboardEvent):Void {
        switch ( event.key ) {
            case Enter:
                super.keyup( event );

            case Tab:
                event.preventDefault();
                trace(getCaretSegment());
                hiliteSegmentByIndex(getCaretSegment() + 1);
                trace(getCaretSegment());
                trace(getSegmentText(getCaretSegment()));
                trace(segments());

            case Up:
                event.preventDefault();

            default:
                //
        }
    }

/* === Instance Fields === */

}

typedef SegmentBound = {x:Int, y:Int};
