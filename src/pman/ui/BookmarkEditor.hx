package pman.ui;

import tannus.ds.*;
import tannus.io.*;
import tannus.events.*;
import tannus.media.Duration;
import tannus.html.Element;

import foundation.*;

import pman.core.*;
import pman.media.*;
import pman.bg.media.Mark;

//import electron.Tools.*;
import edis.Globals.*;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;
using pman.media.MediaTools;

class BookmarkEditor extends Pane {
    /* Constructor Function */
    public function new(player:Player, track:Track):Void {
        super();

        addClass('mark-editor');

        this.player = player;
        this.track = track;
    }

/* === Instance Methods === */

    /**
      * open [this] shit
      */
    public function open():Void {
        __build();
        if (!childOf('body')) {
            appendTo('body');
        }
        defer( center );
    }

    /**
      * close [this] shit
      */
    public function close():Void {
        destroy();
    }

    /**
      * build [this]'s content
      */
    private function __build():Void {
        var hedr = new Heading(3, 'Track Bookmarks');
        append( hedr );
        hedr.css.write({
            'text-align': 'center'
        });
        var table = new Table();
        table.addHeadRows(['name', 'time', '']);
        for (m in track.data.marks) {
            var row = table.addRow();
            var name = (switch ( m.type ) {
                case Begin: "$begin";
                case End: "$end";
                case LastTime: "$lastTime";
                case Scene(SceneBegin, n): '$$scene($${begin}, "$n")';
                case Scene(SceneEnd, n): '$$scene($${end}, "$n")';
                case Named( n ): n;
            });
            var nameCol = row.addCol(null, name);
            var timeCol = row.addCol(null, Duration.fromFloat(m.time).toString());
            var remove = new Button('remove');
            remove.on('click', function(event) {
                event.preventDefault();

                track.data.removeMark( m );
                row.destroy();
            });
            remove.small(true);
            remove.css.write({
                'float': 'right'
            });
            row.addCol(null, remove);

            editable(nameCol, function(d : Delta<String>) {
                rename(m, d.current);
            });
            editable(timeCol, function(d : Delta<String>) {
                retime(m, d.current);
            });
        }
        append( table );

        var flex = new FlexRow([6, 6]);
        append( flex );

        var cancel = new Button('Cancel');
        cancel.expand( true );
        var save = new Button('Save');
        save.expand( true );
        flex.pane( 0 ).append( cancel );
        flex.pane( 1 ).append( save );

        cancel.on('click', function(e) {
            close();
        });
        save.on('click', function(e) {
            track.data.save();
            close();
        });
    }

    /**
      * make the given shit editable
      */
    private function editable(col:TableCol, handler:Delta<String>->Void):Void {
        var before:Null<String> = col.text;
        inline function focus() {
            col.el.at(0).focus();
        }
        inline function blur() {
            col.el.at(0).blur();
        }
        inline function ce(v : Bool):Void {
            if ( v ) {
                col.el.attr('contenteditable', 'true');
            }
            else {
                col.el.removeAttr('contenteditable');
            }
        }
        function submit() {
            if (before.trim() == '') {
                before = null;
            }
            var after:Null<String> = col.text;
            if (after.trim() == '') {
                after = null;
            }
            if (before != after) {
                var delta:Delta<String> = new Delta(after, before);
                handler( delta );
            }
        }
        col.forwardEvent('keydown', null, KeyboardEvent.fromJqEvent);
        col.forwardEvents(['focus', 'blur', 'click']);

        col.on('click', function(event) {
            ce( true );
            defer(function() {
                focus();
            });
        });
        col.on('keydown', function(event : KeyboardEvent) {
            event.stopPropogation();
            switch ( event.key ) {
                case Key.Enter:
                    event.preventDefault();
                    ce( false );
                    submit();

                default:
                    null;
            }
        });
        col.on('focus', function(event) {
            trace('focused');
        });
        col.on('blur', function(event) {
            ce( false );
            submit();
        });
    }

    /**
      * rename the given Mark
      */
    private function rename(mark:Mark, name:String):Void {
        switch ( name ) {
            case "$lastTime":
                mark.type = LastTime;
            case "$begin":
                mark.type = Begin;
            case "$end":
                mark.type = End;
            default:
                mark.type = Named( name );
        }
    }

    /**
      * reassign the 'time' field of the given Mark
      */
    private function retime(mark:Mark, str:String):Void {
        try {
            var time:Float = 0;
            if (str.has(':')) {
                var dur:Duration = Duration.fromString( str );
                time = dur.toFloat();
            }
            else {
                var parsed = Std.parseFloat( str );
                if (Math.isFinite( parsed ) && !Math.isNaN( parsed )) {
                    time = parsed;
                }
            }
            mark.time = time;
        }
        catch (error : Dynamic) {
            return ;
        }
    }

    /**
      * center [this]
      */
    public function center():Void {
		var mr = el.rectangle;
		var pr = new Element( 'body' ).rectangle;
		var c = css;

		var cx:Float = mr.centerX = pr.centerX;
		c['left'] = '${cx}px';
    }

/* === Instance Fields === */

    public var player : Player;
    public var track : Track;
}
