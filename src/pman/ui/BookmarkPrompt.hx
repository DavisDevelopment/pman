package pman.ui;

import foundation.*;

import tannus.io.*;
import tannus.ds.*;
import tannus.html.Element;
import tannus.events.*;
import tannus.events.Key;
import tannus.async.*;

import pman.core.*;
import pman.bg.media.Mark;

import Std.*;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;
using tannus.async.Asyncs;

@:expose
class BookmarkPrompt extends PromptBox {
    /* Constructor Function */
    public function new():Void {
        super();

        addClass('pman-mark-prompt');

        typeSelect = new Select();
        inline function o(n:String, v:PMarkType) return typeSelect.option(n, v);

        o('normal', PMTNamed);
        o('scene', PMTScene);
        o('start time', PMTStartTime);
        o('end time', PMTEndTime);

        inputRow.append( typeSelect );
        typeSelect.onchange.on(_changedMarkType);

        title = 'Create Bookmark';
        placeholder = 'bookmark title';
    }

/* === Instance Methods === */

    /**
      * use [this] Prompt to read a Mark instance
      */
    public function readMark(callback: Null<Mark>->Void):Void {
        open();
        prepHistory(function(?error) {
            readLine(function(line: String) {
                if (mtype == null)
                    mtype = PMTNamed;

                var time:Float = player.currentTime;
                var type:MarkType;
                switch ( mtype ) {
                    case PMTNamed:
                        type = MarkType.Named( line );
                    case PMTStartTime:
                        type = MarkType.Begin;
                    case PMTEndTime:
                        type = MarkType.End;
                    case PMTScene:
                        var t = player.track;
                        var st:SceneMarkType = SceneMarkType.SceneBegin;
                        if (t != null && t.data != null && t.data.marks != null) {
                            for (m in t.data.marks) {
                                if (m.type.match(Scene(SceneBegin, line))) {
                                    st = SceneEnd;
                                    break;
                                }
                            }
                        }
                        type = MarkType.Scene(st, line);
                    default:
                        type = MarkType.Named(line);
                }

                var mark:Mark = new Mark(type, time);
                callback( mark );
            });
            focus();
        });
    }

    /**
      * ensure that [history] is ready to be used
      */
    private function prepHistory(done: VoidCb):Void {
        if (history.empty() && player.track != null && player.track.data != null) {
            var entries = [];
            for (mark in player.track.data.marks) {
                if (mark.type.match(Named(_))) {
                    entries.push( mark );
                }
            }
            entries.sort(function(a, b) {
                return Reflect.compare(a.time, b.time);
            });
            for (m in entries) {
                switch ( m.type ) {
                    case Named(name):
                        history.push( name );

                    default:
                        null;
                }
            }
        }
        done();
    }

    override function __listen():Void {
        super.__listen();

        //typeSelect.forwardEvent('keydown', null, KeyboardEvent.fromJqEvent);
        //typeSelect.on('keydown', function(event: KeyboardEvent))
    }

    /**
      * handle keys
      */
    override function keydown(event : KeyboardEvent):Void {
        switch ( event.key ) {
            case Enter:
                if (mtype != null && mtype.match(PMTStartTime|PMTEndTime)) {
                    line('');
                }
                else if (value.hasContent()) {
                    line(value.trim());
                }
                else {
                    empty();
                }
                close();
                //
            case Up:
                event.cancel();
                if (peekDistance == -1) {
                    originalValue = value;
                }

                peekDistance++;
                if (history[peekDistance] == null) {
                    peekDistance--;
                }

                value = history[peekDistance];
                caret( value.length );

            case Down:
                event.cancel();
                if (peekDistance == -1) {
                    value = originalValue;
                }
                else {
                    value = history[0 + peekDistance--];
                }
                caret( value.length );

            case _:
                peekDistance = -1;
                super.keydown( event );
        }
    }

    /**
      * do the shit
      */
    override function line(l : String):Void {
        //if (l != history[0]) {
            //history.unshift( l );
            addHistoryItem( l );
        //}
        super.line( l );
    }

    /**
      * add an item to the [history]
      */
    private function addHistoryItem(line: String):Void {
        var rem = [];
        for (item in history) {
            if (item.trim() == line.trim()) {
                rem.push( item );
            }
        }
        history = history.without( rem );
        history.unshift(line.trim());
    }

    private function _changedMarkType(d: Delta<PMarkType>):Void {
        var type:PMarkType = d.current;
        if (type == null) type = PMarkType.PMTNamed;

        switch ( type ) {
            case PMTStartTime|PMTEndTime:
                value = '';
                placeholder = 'the selected mark type doesn\'t accept a title';
                //input.el.set('disabled', 'yes');

            case nameable:
                //input.el.removeAttr('disabled');
                placeholder = 'bookmark title';
        }

        defer(function() {
            focus();
        });
    }

/* === Computed Instance Fields === */

    public var mtype(get, set): Null<PMarkType>;
    private inline function get_mtype() return typeSelect.getValue();
    private function set_mtype(v) {
        typeSelect.setValue( v );
        return mtype;
    }

/* === Instance Fields === */

    public var typeSelect : Select<PMarkType>;

    private var peekDistance : Int = -1;
    private var originalValue : String;

/* === Statics === */

    public static var history : Array<String> = {new Array();};
}

/* enum of 'mark type's */
enum PMarkType {
    PMTNamed;
    PMTScene;
    PMTStartTime;
    PMTEndTime;
}
