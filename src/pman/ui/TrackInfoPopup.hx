package pman.ui;

import tannus.ds.*;
import tannus.io.*;
import tannus.geom.*;
import tannus.html.Element;
import tannus.events.*;
import tannus.events.Key;

import crayon.*;
import foundation.*;

import gryffin.core.*;
import gryffin.display.*;

import haxe.Template;

import pman.async.tasks.SaveTrackInfo;

import pman.Globals.*;
import Slambda.fn;

import pman.core.*;
import pman.media.*;
import pman.display.Templates;
import pman.search.Match as SearchMatch;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using Slambda;
using tannus.ds.ArrayTools;
using pman.core.ExecutorTools;

class TrackInfoPopup extends Dialog {
    /* Constructor Function */
    public function new(track : Track):Void {
        super();

        this.track = track;
        this.tmacros = null;
        this.inputs = new Dict();

        addClass('pman-dialog');
        addClass('track-info-dialog');

        build();
    }

/* === Instance Methods === */

    /**
      * build [this]'s content
      */
    override function populate():Void {
        super.populate();

        if (template == null) {
            template = Templates.get( 'track-info' );
        }

        tmacros = {
            tags: function(resolve:Dynamic) {
                return track.data.tags.join(', ');
            },
            stars: function(resolve : Dynamic) {
                return track.data.actors.map.fn( _.name ).join(', ');
            }
        };

        var markup:String = template.execute(track, tmacros);

        append( markup );

        __data();
        __bind();
    }

    /**
      * bind event listeners
      */
    private function __bind():Void {
        cancelButton.on('click', function(event) {
            close();
        });

        saveButton.on('click', function(event) {
            save();
        });

        var kbc = bpmain.keyboardCommands;
        kbc.registerModeHandler('track-info', function(event) {
            return ;
        });
        on('open', untyped function() {
            kbc.mode = 'track-info';
        });
        on('close', untyped function() {
            kbc.mode = 'default';
        });
    }

    /**
      * betty
      */
    private function __data():Void {
        __collectInputs();

        cancelButton = e(el.find('button.cancel'));
        saveButton = e(el.find('button.save'));
    }

    /**
      * obtain object-references to all inputs
      */
    private function __collectInputs():Void {
        var il = e(e(el.find('.data')).find('input,textarea')).toArray();
        for (ie in il) {
            var key:String = ie.attr('name');
            if (key == null) {
                continue;
            }
            else {
                inputs[key] = ie;
            }
        }
    }

    /**
      * get the value of the 'title' input
      */
    private function getTitle():Maybe<String> {
        return ivs( 'title' );
    }

    /**
      * get the value of the 'description' input
      */
    private function getDescription():Maybe<String> {
        return ivs( 'description' );
    }

    /**
      * get the textual value of the 'tags' input
      */
    private function getTagsText():Maybe<String> {
        return ivs( 'tags' );
    }

    /**
      * get the list of tags
      */
    private function getTags():Array<String> {
        return splitThatShit(getTagsText());
    }

    /**
      * separate the given String into its individual values
      */
    private function splitThatShit(s:Maybe<String>):Array<String> {
        // do nothing if [s] is null
        if (s == null) {
            return new Array();
        }
        // do nothing if [s] is empty when trimmed
        else if (s.trim().empty()) {
            return new Array();
        }
        else {
            // create array to hold the ByteArrays
            var ba:Array<String> = new Array();
            // create buffer to hold current segment
            var b:String = '';
            // iterate over each Byte in the String
            for (index in 0...s.length) {
                var c = s.byteAt( index );
                // commas are delimiters
                if (c.equalsChar(',')) {
                    b = b.trim();
                    // if the buffer isn't empty
                    if (b.length > 0) {
                        // add the buffer to the list
                        ba.push( b );
                        // reset the buffer
                        b = '';
                    }
                }
                // add any other Byte to the buffer
                else {
                    b += c;
                }
            }
            b = b.trim();
            // flush the buffer once iteration has stopped
            if (b.length > 0) {
                ba.push( b );
            }
            return ba;
        }
    }

    /**
      * get the textual value of the 'stars' input
      */
    private function getActorsText():Maybe<String> {
        return ivs( 'stars' );
    }

    /**
      * get the list of Actor names
      */
    private function getActors():Array<String> {
        return splitThatShit(getActorsText()).unique();
    }

    /**
      * get the value of the 'rating' input
      */
    private function getRating():Maybe<Float> return ivn('rating');
    private function getContentRating():Maybe<String> return ivs('content-rating');
    private function getChannel():Maybe<String> return ivs('channel');

    /**
      * get an input's value as a String
      */
    private function ivs(name:String):Maybe<String> {
        return i( name ).ternary(_.val(), null);
    }

    /**
      * get an input's value as a Float
      */
    private function ivn(name : String):Maybe<Float> {
        return i( name ).ternary(_.prop('valueAsNumber'), null);
    }

    /**
      * get an input element
      */
    private function i(name : String):Maybe<Element> {
        return inputs[name];
    }

    /**
      * get the form value
      */
    public function getFormValue():TrackInfoFormValue {
        return {
            title: getTitle(),
            description: getDescription(),
            tags: getTags(),
            actors: getActors(),
            rating: getRating(),
            channel: getChannel(),
            contentRating: getContentRating()
        };
    }

    /**
      * get the changes that have been made to the form value
      */
    public function getFormValueDelta():TrackInfoFormValueDelta {
        var v = getFormValue();
        var d = track.data;
        var delta:TrackInfoFormValueDelta = {};
        if (track.title != v.title) {
            delta.title = new Delta(v.title, track.title);
        }
        if (d.description != v.description) {
            delta.description = new Delta(v.description, d.description);
        }
        if (d.rating != v.rating) {
            delta.rating = new Delta(v.rating, d.rating);
        }
        if (v.tags.length != d.tags.length) {
            delta.tags = new Delta(v.tags, d.tags.map.fn(_.name));
        }
        else {
            var vt = v.tags.copy();
            var dt = d.tags.map.fn( _.name );
            vt.sort( Reflect.compare );
            dt.sort( Reflect.compare );
            if (!vt.compare( dt )) {
                delta.tags = new Delta(vt, dt);
            }
        }
        var danl:Array<String> = d.actors.map.fn( _.name );
        if (v.actors.length != danl.length) {
            delta.actors = new Delta(v.actors, danl);
        }
        else {
            var vanl = v.actors.copy();
            vanl.sort( Reflect.compare );
            danl.sort( Reflect.compare );
            if (!vanl.compare( danl )) {
                delta.actors = new Delta(vanl, danl);
            }
        }
        if (v.channel != d.channel) {
            delta.channel = new Delta(v.channel, d.channel);
        }
        if (v.contentRating != d.contentRating) {
            delta.contentRating = new Delta(v.contentRating, d.contentRating);
        }
        return delta;
    }

    /**
      * save the value of [this] form
      */
    private function save():Void {
        trace(getFormValue());
        // compute delta
        var delta = getFormValueDelta();
        // create task to save changes
        var saver = new SaveTrackInfo(track, delta);
        // execute that task
        saver.run(function(?error) {
            if (error != null) {
                report( error );
            }
            close();
            destroy();
        });
    }

/* === Instance Fields === */

    public var track : Track;

    public var inputs : Dict<String, Element>;
    public var cancelButton : Element;
    public var saveButton : Element;
    
    private var tmacros : Dynamic;

/* === Static Fields === */

    private static var template : Null<Template> = null;
}

typedef TrackInfoFormValue = {
    title : String,
    description : String,
    tags : Array<String>,
    actors : Array<String>,
    channel: Null<String>,
    rating : Null<Float>,
    contentRating : Null<String>
};
