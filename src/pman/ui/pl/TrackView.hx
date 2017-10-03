package pman.ui.pl;

import tannus.io.*;
import tannus.html.Element;
import tannus.geom.*;
import tannus.events.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;
import tannus.media.Duration;

import crayon.*;

import gryffin.core.*;
import gryffin.display.*;
import foundation.*;
import vex.core.*;

import electron.ext.*;
import electron.ext.Dialog;

import pman.core.*;
import pman.media.*;
import pman.display.*;
import pman.Globals.*;

import haxe.Template;

import Slambda.fn;
import tannus.math.TMath.*;

using StringTools;
using Lambda;
using Slambda;
using tannus.math.TMath;
using pman.Tools;
using pman.core.ExecutorTools;

class TrackView extends Pane {
	/* Constructor Function */
	public function new(v:PlaylistView, t:Track):Void {
		super();

		addClass( 'track' );

		list = v;
		track = t;

		build();
	}

/* === Instance Methods === */

	/**
	  * Build [this] 
	  */
	override function populate():Void {
	    // ensure that [template] exists
	    if (template == null) {
	        template = Templates.get( 'track-item' );
        }

        // create the track macros
	    tmacros = {
            duration: function(resolve:Dynamic):String {
                if (track.data != null) {
                    return Duration.fromFloat( track.data.meta.duration ).toString();
                }
                else {
                    var path = track.getFsPath();
                    if (path != null) {
                        var stat = Fs.stat( path );
                        return stat.size.formatSize();
                    }
                    else {
                        return '?';
                    }
                }
            },
            progress: function(resolve:Dynamic):String {
                if (track.data != null) {
                    var lt = track.data.getLastTime();
                    if (lt != null) {
                        var perc = tannus.math.Percent.percent(lt, track.data.meta.duration);
                        return perc.toString();
                    }
                    else {
                        return '0%';
                    }
                }
                else return '0%';
            }
	    };

        // initialize events
		if ( !eventInitted ) {
		    __events();
		}

        // set some attributes
		var a = this.el.attributes;
		a['title'] = track.title;
		a['data-uri'] = track.uri;

		var data = this.el.edata;
		data['view'] = this;

		update();

		needsRebuild = false;
	}

	/**
	  * update [this]'s content
	  */
	public function update():Void {
	    var td = track.data;

        // generate the markup
        var markup = template.execute(track, tmacros);

        // clear [el] of its content
        el.html('');

        // append the markup
        append( markup );
	}

	/**
	  * configure events and such
	  */
	private function __events():Void {
        forwardEvents(['click', 'contextmenu', 'mousedown', 'mouseup', 'mousemove'], null, MouseEvent.fromJqEvent);
        on('click', onLeftClick);
		on('contextmenu', onRightClick);

		el.plugin( 'disableSelection' );

		eventInitted = true;
	}

	/**
	  * handle a Click
	  */
	private function onLeftClick(event : MouseEvent):Void {
		event.cancel();

        if (event.ctrlKey || list.anySelected()) {
            selected = !selected;
        }
        else {
            if (player.track != track) {
                player.openTrack( track );
            }
        }
	}
	
	/**
	  * handle right click
	  */
	private function onRightClick(event : MouseEvent):Void {
		event.cancel();

        if ( selected ) {
            list.getTrackSelection().buildMenu(function(template) {
                var menu:Menu = template;
                menu.popup();
            });
        }
        else {
            list.selectTracks.fn(x => false);
            track.buildMenu(function( template ) {
                var menu:Menu = template;
                menu.popup();
            });
        }
	}

    /**
      * permanently destroy [this] TrackView
      */
	override function destroy():Void {
        super.detach();
        //needsRebuild = true;
	}
	
	/**
	  * detach [this] TrackView
	  */
	override function detach():Void {
        super.detach();
		//needsRebuild = true;
	}

	/**
	  * Whether [this] Track is focused
	  */
	public function focused(?value : Bool):Bool return c('focused', value);

	/**
	  * Whether [this] Track is hovered
	  */
	public function hovered(?value : Bool):Bool return c('hovered', value);

	/**
	  * get the status of a flag
	  */
	private function cg(name : String):Bool {
		return el.hasClass( name );
	}

	/**
	  * set the status of a flag
	  */
	private function cs(name:String, value:Bool):Void {
		(value ? addClass : removeClass)( name );
	}

	/**
	  * (if provided) assign the status of the [name] flag
	  * and return the status of the [name] flag
	  */
	private function c(name:String, ?value:Bool):Bool {
		if (value != null) {
			cs(name, value);
		}
		return cg( name );
	}

    /**
      * get the boolean value of an attribute
      */
    private function _ag(name : String):Bool {
        return !(untyped [null, 'false', 'f'].has(el.attr(name)));
    }

    /**
      * set the boolean value of an attribute
      */
    private function _as(name:String, value:Bool):Void {
        if (!value)
            el.removeAttr( name );
        else
            el.attr(name, 'true');
    }

    /**
      * get or set the Boolean value of an attribute
      */
    private function a(name:String, ?value:Bool):Bool {
        if (value != null) {
            _as(name, value);
        }
        return _ag( name );
    }

/* === Computed Instance Fields === */

	public var player(get, never):Player;
	private inline function get_player():Player return list.player;

	public var session(get, never):PlayerSession;
	private inline function get_session():PlayerSession return list.session;

	public var playlist(get, never):Playlist;
	private inline function get_playlist():Playlist return list.playlist;
	
	public var li(get, never):ListItem;
	private inline function get_li():ListItem return cast this.parentWidget;

    // whether [this] widget is highlighted
	public var selected(get, set):Bool;
	private inline function get_selected():Bool return cg('selected');
	private inline function set_selected(v) return c('selected', v);

/* === Instance Fields === */

    public var flex : FlexRow;
    public var needsRebuild:Bool = false;
	public var list : PlaylistView;
	public var track : Track;

	public var title : FlexPane;
	public var info : FlexPane;
	public var buttons : Pane;
	public var size : Pane;
	public var progressTrack : Pane;
	public var progress : Pane;

	public var tmacros : Dynamic;

	private var menuOpen : Bool = false;
	private var eventInitted : Bool = false;
	@:allow( pman.ui.PlaylistView )
	private var dragging : Bool = false;

	private static var template : Null<Template> = null;
}
