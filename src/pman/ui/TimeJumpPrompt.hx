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
import pman.Globals.*;

import Std.*;
import tannus.math.TMath.*;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;

class TimeJumpPrompt extends PromptBox {
    /* Constructor Function */
    public function new():Void {
        super();

        el['id'] = 'jump';
        el.data('model', this);
        addClass('goto-time-prompt');

        title = 'goto time';
    }

/* === Instance Methods === */

    /**
      * set [this]'s value by time
      */
    public function setTime(time : Duration):Void {
        value = time.toString();
    }

    /**
      * get [this]'s value as a time
      */
    public function getTime():Duration {
        try {
            return Duration.fromString( value );
        }
        catch (error : Dynamic) {
            return Duration.fromFloat( player.currentTime );
        }
    }

    /**
      * get the indices of the boundaries of each segment of [this]'s value
      */
    private function sepIndices(edges:Bool=false):Array<Int> {
        var s = value, char:String;
        var indices = [0];
        for (index in 0...s.length) {
            char = s.charAt( index );
            if (char == ':') {
                indices = indices.concat([index, (index + 1)]);
            }
        }
        indices.push(s.length);
        return indices;
    }

    /**
      * get the boundaries of each segment
      */
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

    /**
      * select a segment
      */
    public function selectSegmentByIndex(index:Int=0, ?segs:Array<SegmentBound>):Void {
        if (segs == null)
            segs = segments();
        var bounds = segs[index];
        if (bounds != null) {
            selectSegment( bounds );
        }
    }

    /**
      * select a segment
      */
    public inline function selectSegment(?segment : SegmentBound):Void {
        if (segment == null)
            segment = segments()[0];
        selectRange(segment.x, segment.y);
    }

    /**
      * get the index of the segment that the cursor is inside of currently
      */
    public function getCaretSegmentIndex(?segs:Array<SegmentBound>):Int {
        if (segs == null)
            segs = segments();
        var cursor = caret();
        for (index in 0...segs.length) {
            if (cursor >= segs[index].x && cursor <= segs[index].y) {
                return index;
            }
            else continue;
        }
        return -1;
    }

    /**
      * get the text of a segment
      */
    public inline function getSegmentText(segment:SegmentBound):Maybe<String> {
        if (segment != null) {
            return value.substring(segment.x, segment.y);
        }
        else return null;
    }

    /**
      * set the textual value of a particular segment
      */
    public function setSegmentTextByIndex(index:Int, segmentText:String, ?segs:Array<SegmentBound>, ?csi:Int):String {
        var txt:String = value;
        if (segs == null)
            segs = segments();
        if (csi == null)
            csi = getCaretSegmentIndex( segs );
        //var index:Int = indexOfSegment(segment, segs);
        var segment:SegmentBound = segs[index];
        var before:Null<Array<String>> = null, after:Null<Array<String>> = null;
        if (index > 0) {
            //before = [for (i in 0...index) getSegmentText(i, segs)];
            before = segs.before(segment).map.fn(getSegmentText(_));
        }
        if (index < (segs.length - 1)) {
            //after = [for (i in (index + 1)...(segs.length - 1)) getSegmentText(i, segs)];
            after = segs.after(segment).map.fn(getSegmentText(_));
        }
        var resultPieces = [];
        if (before != null) {
            resultPieces = resultPieces.concat( before );
        }
        resultPieces.push( segmentText );
        if (after != null) {
            resultPieces = resultPieces.concat( after );
        }
        var result = (value = resultPieces.join(':'));
        selectSegmentByIndex(csi, segs);
        return result;
    }

    public function setSegmentText(segment:SegmentBound, segmentText:String, ?segs:Array<SegmentBound>):String {
        if (segs == null)
            segs = segments();
        var index:Int = indexOfSegment(segment, segs);
        trace( index );
        return setSegmentTextByIndex(index, segmentText, segs);
    }

    public inline function getSegmentValue(segment:SegmentBound):Maybe<Int> {
        return getSegmentText( segment ).ternary(Std.parseInt(_), null);
    }

    public function setSegmentValue(segment:SegmentBound, nval:Int, ?segs:Array<SegmentBound>):Int {
        nval = nval.rclamp(0, 59);
        var sval:String = (nval + '').lpad('0', 2);
        setSegmentText(segment, sval, segs);
        return nval;
    }

    public function setSegmentValueByIndex(index:Int, nval:Int, ?segs:Array<SegmentBound>):Int {
        if (segs == null)
            segs = segments();
        return setSegmentValue(segs[index], nval, segs);
    }

    public function getCaretSegment(?segs:Array<SegmentBound>):SegmentBound {
        if (segs == null)
            segs = segments();
        return segs[getCaretSegmentIndex( segs )];
    }

    public function getCaretSegmentValue():Maybe<Int> {
        return getSegmentValue(getCaretSegment());
    }

    public function setCaretSegmentValue(nval : Int):Int {
        return setSegmentValue(getCaretSegment(), nval);
    }

    public function modCaretSegmentValue(n : Int):Void {
        setCaretSegmentValue(getCaretSegmentValue() + n);
    }

    /**
      * get index of segment, obviously
      */
    private function indexOfSegment(segment:SegmentBound, ?segs:Array<SegmentBound>):Int {
        if (segs == null)
            segs = segments();
        for (index in 0...segs.length) {
            if (segs[index].x == segment.x && segs[index].y == segment.y) {
                return index;
            }
        }
        return -1;
    }

    /**
      * move to and select the next segment
      */
    public function nextSegment(create:Bool=false):Void {
        var start:Int=null, end:Int=null;
        var cursor = caret();
        if (cursor == value.length) {
            if ( create ) {
                value += ':00';
                selectRange((value.lastIndexOf(':') + 1), value.length);
                return ;
            }
            else {
                start = 0;
                caret(0);
            }
        }
        for (index in caret()...(value.length - 1)) {
            var char = value.charAt(index);
            if (char == ':') {
                if (start == null) {
                    start = (index + 1);
                }
                else if (end == null) {
                    end = index;
                }
                else {
                    break;
                }
            }
        }
        if (end == null)
            end = value.length;
        selectRange(start, end);
    }

    /**
      * handle events
      */
    override function __listen():Void {
        super.__listen();

        input.forwardEvents(['focus', 'focusin', 'blur']);
        input.on('focus', function(event) {
            //TODO
        });

        // handle focusin events
        input.on('focusin', function(event) {
            selectSegmentByIndex();
        });

        // handle 'blur' events
        input.on('blur', function(event) {
            defer(function() {
                focus();
            });
        });
    }

    /**
      * handle keydown events
      */
    override function keydown(event : KeyboardEvent):Void {
        switch ( event.key ) {
            case Enter:
                attemptSubmit();

            case Tab:
                cancelNextKeyUp( Tab );
                event.preventDefault();
                nextSegment();

            case SemiColon if ( event.shiftKey ):
                event.preventDefault();
                nextSegment( true );

            case Up:
                event.preventDefault();
                modCaretSegmentValue( 1 );

            case Down:
                event.preventDefault();
                modCaretSegmentValue( -1 );

            case Equals if ( event.shiftKey ):
                var index = getCaretSegmentIndex();
                if (index == 0) {
                    value = '';
                }
                else {
                    event.preventDefault();
                }

            default:
                super.keydown( event );
        }
    }

    /**
      * do the stuff, poot cakes
      */
    public function readTime(player:Player, ?done:VoidCb):Void {
        open();
        setTime( player.currentTime );
        once('time', function(time : Duration) {
            player.currentTime = time.toFloat();
            el.plugin('hide', untyped [
                'drop',
                null,
                300,
                function() {
                    close();
                    if (done != null) {
                        done( null );
                    }
                }
            ]);
        });
        focus();
        defer(function() {
            selectSegmentByIndex();
        });
    }

    /**
      * check that [this]'s value is valid input
      */
    public function isValidInput():Bool {
        try {
            var time = Duration.fromString( value );
            trace( time );
            return true;
        }
        catch (error : Dynamic) {
            return false;
        }
    }

    /**
      * the user has just attempted to 'submit'
      */
    public function attemptSubmit():Void {
        if (isValidInput()) {
            dispatch('time', getTime());
        }
        else {
            select();
            el.plugin('effect', ['shake']);
        }
    }

/* === Instance Fields === */

}

typedef SegmentBound = {x:Int, y:Int};
