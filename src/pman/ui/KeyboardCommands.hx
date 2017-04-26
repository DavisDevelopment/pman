package pman.ui;

import tannus.events.*;
import tannus.events.Key;

import Std.*;
import tannus.math.TMath.*;
import gryffin.Tools.defer;

import pman.core.*;

import electron.ext.*;
import electron.ext.GlobalShortcut in Gs;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class KeyboardCommands {
	/* Constructor Function */
	public function new(app : BPlayerMain):Void {
		this.app = app;

		_nextKeyDown = new Array();
        _nextKeyUp = new Array();
		//commands = new Map();
	}

/* === Instance Methods === */

	/**
	  * bind all commands
	  */
	public function bind():Void {
	    var target = app.playerPage.stage;
		target.on('keydown', handleKeyDown);
		target.on('keyup', handleKeyUp);
	}

	/**
	  * unbind all commands
	  */
	public function unbind():Void {
	    var target = app.playerPage.stage;
	    target.off('keydown', handleKeyDown);
	    target.off('keyup', handleKeyUp);
	}

	/**
	  * intercept the next 'keydown' event
	  */
	public inline function nextKeyDown(f : KeyboardEvent->Void):Void {
	    _nextKeyDown.push( f );
	}

	/**
	  * intercept the next 'keyup' event
	  */
	public inline function nextKeyUp(f : KeyboardEvent->Void):Void {
	    _nextKeyUp.push( f );
	}

    /**
      * handle 'keydown' events
      */
	private function handleKeyDown(event : KeyboardEvent):Void {
	    if (_nextKeyDown.length > 0) {
            _nextKeyDown.iter.fn(_( event ));
            _nextKeyDown = [];
            return ;
	    }

		switch ( event.key ) {
			// Space
			case Space:
				p.togglePlayback();

			// N
			case LetterN, Key.NumpadPlus:
				//p.gotoNext();
				p.gotoByOffset(fncc());

			// P or -
			case LetterP, Key.NumpadMinus:
			    if ( event.shiftKey ) {
			        p.gotoByOffset( -1 );
			    }
                else {
                    var n = fncc();
                    if (n == 1)
                        p.gotoPrevious();
                    else
                        p.gotoByOffset( n );
                }

            // Backspace
            case Backspace:
                p.startOver();

			// X
			case LetterX:
			    var ct = sess.focusedTrack;
			    if (ct != null) {
			        p.gotoByOffset( 1 );
			        sess.playlist.remove( ct );
			    }

            // snapshot
            case LetterS if ( event.shiftKey ):
                p.snapshot();

            // toggle controls visibility
			case LetterH:
				p.view.controls.uiEnabled = !p.view.controls.uiEnabled;

			// Right Arrow key
			case Right:
				var n:Float = seekTimeDelta( event );
				p.currentTime += n;

			// Left Arrow key
			case Left:
				var n:Float = -seekTimeDelta( event );
				p.currentTime += n;

            // Up Arrow Key
			case Up:
			    var n:Float = volumeDelta( event );
			    p.volume += n;

			// Down Arrow Key
			case Down:
			    var n:Float = -volumeDelta( event );
			    p.volume += n;

			// [ key
			case OpenBracket:
				p.playbackRate -= (fncc() * 0.02);

			// ] key
			case CloseBracket:
				p.playbackRate += (fncc() * 0.02);

			// =
			case Equals:
				p.playbackRate = 1.0;

			// M
			case LetterM:
				if ( event.ctrlKey ) {
					p.addBookmark();
				}
				else {
					p.muted = !p.muted;
				}

            // *
            case NumpadAsterisk:
                if (p.track != null) {
                    p.track.toggleStarred();
                }
            case Number8 if ( event.shiftKey ):
                if (p.track != null) {
                    p.track.toggleStarred();
                }

            // bookmark navigation
            case BackTick, LetterB:
                // initiate that shit
                p.view.controls.seekBar.bookmarkNavigation();

            // :
            case SemiColon if ( event.shiftKey ):
                defer(function() {
                    p.prompt('pmbash', null, null, function(line : Null<String>) {
                        trace('cmd: $line');
                    });
                });

		/* --- 'next-command-count' modifiers --- */

			case Number0, Numpad0:
				mncc( 0 );

			case Number1, Numpad1:
				mncc( 1 );

			case Number2, Numpad2:
				mncc( 2 );

			case Number3, Numpad3:
				mncc( 3 );

			case Number4, Numpad4:
				mncc( 4 );

			case Number5, Numpad5:
				mncc( 5 );

			case Number6, Numpad6:
				mncc( 6 );

			case Number7, Numpad7:
				mncc( 7 );

			case Number8, Numpad8:
				mncc( 8 );

			case Number9, Numpad9:
				mncc( 9 );

			default:
				null;
		}
	}

	/**
	  * handle key-up events
	  */
	private function handleKeyUp(event : KeyboardEvent):Void {
	    if (_nextKeyUp.length > 0) {
	        _nextKeyUp.iter.fn(_( event ));
	        _nextKeyUp = [];
	        return ;
	    }

	    switch ( event.key ) {
            default:
                null;
	    }
	}

	/**
	  * get the seek time delta from the given Event
	  */
	private function seekTimeDelta(event : KeyboardEvent):Float {
		var n:Float = 0;
		// frame-by-frame mode
		if ( event.altKey ) {
			if ( event.shiftKey ) {
				n = (5.0 / 30);
			}
			else if ( event.ctrlKey ) {
				n = (10.0 / 30);
			}
			else {
				n = (1.0 / 30);
			}
		}
		else {
			if ( event.shiftKey ) {
				n = 10.0;
			}
			else if ( event.ctrlKey ) {
				n = 30.0;
			}
			else {
				n = 2.0;
			}
		}
		n = (n * fncc());
		return n;
	}

    /**
      * get the amount by which the volume will be changed
      */
	private function volumeDelta(event : KeyboardEvent):Float {
	    var n:Float = 5.0;
	    if ( event.shiftKey ) {
	        n = 1.0;
	    }
	    return (n / 100);
	}

	/**
	  * modifies [nextCmdCount] field, in much the same way as typing number keys on a calculator
	  */
	private inline function modifyNextCmdCount(n : Int):Int {
		return nextCmdCount = ((nextCmdCount * 10) + n);
	}
	private inline function mncc(n:Int):Int return modifyNextCmdCount( n );

	/**
	  * returns and resets [nextCmdCount]
	  */
	private function flushNextCmdCount():Int {
		var n:Int = nextCmdCount;
		nextCmdCount = 0;
		return max(n, 1);
	}
	private inline function fncc():Int return flushNextCmdCount();

	/**
	  * register a keyboard command
	  */
	//private inline function cmd(accelerator:String, f:Void->Void):Void {
		//Gs.register(accelerator, f);
		//commands[accelerator] = f;
	//}

/* === Computed Instance Fields === */

	private var p(get, never):Player;
	private inline function get_p():Player return app.player;

	private var sess(get, never):PlayerSession;
	private inline function get_sess():PlayerSession return p.session;

/* === Instance Fields === */

	public var app : BPlayerMain;

    private var _nextKeyDown:Array<KeyboardEvent->Void>;
    private var _nextKeyUp:Array<KeyboardEvent->Void>;
	private var nextCmdCount : Int;

	//private var commands : Map<String, Void->Void>;
}
