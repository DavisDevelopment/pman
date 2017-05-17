package pman.ui.pl;

import tannus.io.*;
import tannus.html.Element;
import tannus.geom.*;
import tannus.events.*;
import tannus.sys.*;
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

import Slambda.fn;
import tannus.math.TMath.*;

using StringTools;
using Lambda;
using Slambda;
using tannus.math.TMath;
using pman.Tools;

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

        flex = new FlexRow([12, 0]);
        append( flex );

		title = flex.pane( 0 );
		title.addClass( 'title' );
		title.columns.on('small').is( 12 );
		title.columns.on('small').expand = true;
		title.columns.on('large').is( 9 );

        info = flex.pane( 1 );
        info.addClass('info');
        info.columns.on('small').remove();
        info.columns.on('large').is( 3 );
        info.addClass( 'hide-for-small-only' );
        info.addClass( 'hide-for-medium-only' );

		size = new Pane();
		size.addClass( 'size' );
		info.append( size );

		progressTrack = new Pane();
		progressTrack.addClass( 'progress-track' );
		append( progressTrack );

		progress = new Pane();
		progress.addClass( 'progress' );
		progressTrack.append( progress );
		progress.css.set('width', '25%');

		/*
		buttons = new Pane();
		buttons.addClass('actions');
		info.append( buttons );
		*/

		if ( !eventInitted ) {
		    __events();
		}

		var a = this.el.attributes;
		a['title'] = track.title;
		a['data-uri'] = track.uri;

		var data = this.el.edata;
		data['view'] = this;

		needsRebuild = false;

	    update();
	}

	/**
	  * update [this]'s content
	  */
	public function update():Void {
	    var td = track.data;

        title.text = track.title;
        // view counter
        if (td != null) {
            var uw:Element = '<span class="unwatched"><sup>(U)</sup>&nbsp;</span>';
            if (td.views == 0)
                title.el.prepend( uw );
            if ( td.starred ) {
                title.el.prepend('<span class="starred">*</span>');
            }
            else {
                title.el.remove('span.starred');
            }
        }

        // Track Size
        if (td != null && td.meta != null) {
            var tdm = td.meta;
            var dur = Duration.fromFloat( tdm.duration );
            size.text = dur.toString();

            if (tdm.video != null) {
                var res = (tdm.video.height + 'p');
                size.el.prepend('<span class="resolution">($res)</span>');
            }
            else {
                size.el.remove('span.resolution');
            }
        }
        else {
            var trackPath = track.getFsPath();
            if (trackPath == null) {
                size.text = '';
            }
            else {
                var stats = FileSystem.stat( trackPath );
                size.text = stats.size.formatSize();
            }
        }

        if (td != null && td.meta != null) {
            var lt = td.getLastTime();
            if (lt == null) {
                progress.css.set('width', '0%');
            }
            else {
                var perc = tannus.math.Percent.percent(lt, td.meta.duration);
                progress.css.set('width', perc.toString());
            }
        }
	}

	/**
	  * configure events and such
	  */
	private function __events():Void {
        forwardEvents(['click', 'contextmenu', 'mousedown', 'mouseup', 'mousemove'], null, MouseEvent.fromJqEvent);
        on('click', onLeftClick);
		on('contextmenu', onRightClick);

		el.plugin( 'disableSelection' );

		//configureDragAndDropRearrangement();

		eventInitted = true;
	}

	/**
	  * handle a Click
	  */
	private function onLeftClick(event : MouseEvent):Void {
		event.cancel();

		if (player.track != track) {
			player.openTrack( track );
		}
	}
	
	/**
	  * handle right click
	  */
	private function onRightClick(event : MouseEvent):Void {
		event.cancel();

        track.buildMenu(function( template ) {
            var menu:Menu = template;
            menu.popup();
        });
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
	public inline function focused(?value : Bool):Bool return c('focused', value);

	/**
	  * Whether [this] Track is hovered
	  */
	public inline function hovered(?value : Bool):Bool return c('hovered', value);

	/**
	  * get the status of a flag
	  */
	private inline function cg(name : String):Bool {
		return el.hasClass( name );
	}

	/**
	  * set the status of a flag
	  */
	private inline function cs(name:String, value:Bool):Void {
		(value ? addClass : removeClass)( name );
	}

	/**
	  * (if provided) assign the status of the [name] flag
	  * and return the status of the [name] flag
	  */
	private inline function c(name:String, ?value:Bool):Bool {
		if (value != null) {
			cs(name, value);
		}
		return cg( name );
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

	private var menuOpen : Bool = false;
	private var eventInitted : Bool = false;
	@:allow( pman.ui.PlaylistView )
	private var dragging : Bool = false;
}
