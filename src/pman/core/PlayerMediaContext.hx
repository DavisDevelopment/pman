package pman.core;

import tannus.io.*;
import tannus.ds.*;
import tannus.events.*;
import tannus.sys.*;
import tannus.async.*;

import gryffin.core.*;
import gryffin.display.*;

import pman.display.*;
import pman.display.media.*;
import pman.media.*;

import edis.Globals.*;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.async.Asyncs;

@:allow( pman.core.PlayerSession )
@:allow( pman.core.Player )
class PlayerMediaContext {
	/* Constructor Function */
	public function new(session : PlayerSession):Void {
		this.session = session;
		this.changeEvent = new Signal();

		_nullify();
	}

/* === Instance Methods === */

	/**
	  * set the current state
	  */
	public function set(info:MediaContextInfo, done:VoidCb):Void {
        // store current state
        var prev = get();
	    vsequence(function(add, exec) {
            // disassemble if necessary
            if (allValuesPresent()) {
                add(disassemble.bind(_, false));
            }

            // assign state
            if (_validateInfo( info )) {
                add(function(next) {
                    mediaProvider = info.mediaProvider;
                    media = info.media;
                    mediaDriver = info.mediaDriver;
                    mediaRenderer = info.mediaRenderer;

                    next();
                });

                add(function(next) {
                    vsequence(function(push, run) {
                        // if [this] now has media
                        if (allValuesPresent()) {
                            // attach that media's renderer to the Player's view
                            push(view.attachRenderer.bind(mediaRenderer, _));
                        }
                        // if [this] had media, but no longer does
                        else if (prev.allValuesPresent()) {
                            push( view.detachRenderer );
                        }

                        run();
                    }, next);
                });
            }

            // report change
            exec();
        }, done.wrap(function(_, ?error) {
            if (error != null) {
                _( error );
            }
            else {
                _changed(prev, get());
                _();
            }
        }));
	}

	/**
	  * get the current state
	  */
	public function get():MediaContextInfo {
		_polarize();
		return {
			mediaProvider : mediaProvider,
			media : media,
			mediaDriver : mediaDriver,
			mediaRenderer : mediaRenderer
		};
	}

	/**
	  * disassemble, and nullify data state
	  */
	public function disassemble(done:VoidCb, report:Bool=true):Void {
        _polarize();
        var prev = get();
	    vsequence(function(add, exec) {
            if (allValuesPresent()) {
                add( media.dispose );
                add(function(next) {
                    mediaDriver.stop();
                    next();
                });

                _nullify();
            }

            exec();
        }, done.wrap(function(_, ?error) {
            if (error != null) {
                _( error );
            }
            else {
                if ( report ) {
                    _changed(prev, get());
                }
                _();
            }
        }));
	}

	/**
	  * ensure that either all fields have non-null values, or none do
	  */
	private inline function _polarize():Void {
		if (!allValuesPresent()) {
			_nullify();
		}
	}

	/**
	  * check that all fields are non-null
	  */
	private function allValuesPresent():Bool {
		return (
			(mediaProvider != null) &&
			(media != null) && 
			(mediaDriver != null) &&
			(mediaRenderer != null)
		);
	}

	/**
	  * set all fields to null
	  */
	private inline function _nullify():Void {
		mediaProvider = null;
		media = null;
		mediaDriver = null;
		mediaRenderer = null;
	}

	/**
	  * validate the given MediaContextInfo
	  */
	private function _validateInfo(info : MediaContextInfo):Bool {
		var flags:Array<Bool> = [
			(info.mediaProvider != null),
			(info.media != null),
			(info.mediaDriver != null),
			(info.mediaRenderer != null)
		];

		switch ( flags ) {
			/*
			   [info] is considered 'valid' if:
			   A) none of its fields are NULL
			   B) all of them are
			*/
			case [true, true, true, true], [false, false, false, false]:
				return true;

			// in any other case, it is 'invalid'
			default:
				return false;
		}
	}

	/**
	  * create and dispatch the changed event
	  */
	private function _changed(from_:MediaContextInfo, to_:MediaContextInfo):Void {
		var delta:Delta<MediaContextInfo> = new Delta(to_, from_);
		trace('Media Context Change Event');
		changeEvent.call( delta );
	}

/* === Computed Instance Fields === */

	public var player(get, never):Player;
	private inline function get_player():Player return session.player;

	private var view(get, never):PlayerView;
	private inline function get_view():PlayerView return player.view;

/* === Instance Fields === */

	public var session : PlayerSession;

	public var mediaProvider(default, null): Null<MediaProvider>;
	public var media(default, null): Null<Media>;
	public var mediaDriver(default, null): Null<MediaDriver>;
	public var mediaRenderer(default, null): Null<MediaRenderer>;

	public var changeEvent : Signal<Delta<MediaContextInfo>>;
}

@:structInit
class MediaContextInfo {
/* === Instance Fields === */

	@:optional
	public var mediaProvider : Null<MediaProvider>;

	@:optional 
	public var media : Null<Media>;

	@:optional
	public var mediaDriver : Null<MediaDriver>;

	@:optional
	public var mediaRenderer : Null<MediaRenderer>;

/* === Instance Methods === */

	/**
	  * create and return a shallow copy of [this]
	  */
	public function clone():MediaContextInfo {
		return {
			mediaProvider : mediaProvider,
			media : media,
			mediaDriver : mediaDriver,
			mediaRenderer : mediaRenderer
		};
	}

	/**
	  * check that none of [this]'s fields are null
	  */
	public function allValuesPresent():Bool {
		return (
			(mediaProvider != null) &&
			(media != null) && 
			(mediaDriver != null) &&
			(mediaRenderer != null)
		);
	}
}
