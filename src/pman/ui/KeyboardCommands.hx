package pman.ui;

import tannus.ds.Dict;
import tannus.ds.Maybe;
import tannus.events.*;
import tannus.events.Key;
import tannus.math.Random;
import tannus.media.Duration;

import Std.*;
import tannus.math.TMath.*;
import gryffin.Tools.*;

import pman.core.*;
import pman.format.pmsh.*;
import pman.pmbash.*;
import pman.events.*;
import pman.events.KeyboardEventDescriptor as Ked;
import pman.events.KeyboardEventType;
import pman.events.KeyboardEventType as Ket;
import pman.sid.Clipboard as Clip;
import pman.Globals.*;

import electron.ext.*;
import electron.ext.GlobalShortcut in Gs;
import electron.Tools.defer;

import Slambda.fn;

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
		hkc = new HotkeyController();
		_initHkc();
		modeHandlers = new Dict();
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
      * 
      */
	private function _initHkc():Void {
	    var c = hkc.down;

        c.anyOn(function(e) {
            if (e.key == Key.LetterE) {
                e.stopPropogation();
                c.inextWithin(fn(_.key == LetterI), function(status) {
                    if ( status ) {
                        trace('sequence <E,I>');
                    }
                    else {
                        trace('sequence failed');
                    }
                });
            }
        });
	}

	/**
	  * emulate the default handling of the given event
	  */
	public function handleDefault(event : KeyboardEvent):Void {
	    var _mode = mode;
	    mode = 'default';
	    handleKeyDown( event );
	    mode = _mode;
	}

	/**
	  * register a mode handler
	  */
	public function registerModeHandler(modeName:String, handler:KeyboardEvent->Void):Void {
	    modeHandlers[modeName] = handler;
	}

    /**
      * deregister a mode handler
      */
	public function deregisterModeHandler(modeName : String):Bool {
	    return modeHandlers.remove( modeName );
	}

    /**
      * check registry for a handler for the given mode
      */
	public function hasModeHandler(modeName : String):Bool {
	    return modeHandlers.exists( modeName );
	}

    /**
      * obtain a mode handler
      */
	public function getModeHandler(modeName : String):Maybe<KeyboardEvent->Void> {
	    return modeHandlers[modeName];
	}

	/**
	  * extend a mode handler
	  */
	public function extendModeHandler(parentModeName:String, modeName:String, handler:(KeyboardEvent->Void)->KeyboardEvent->Void):Void {
	    var parentHandler:Null<KeyboardEvent->Void> = modeHandlers[parentModeName];
	    if (parentHandler == null) {
	        throw new js.Error('No handler for mode "$parentModeName"; Cannot extend');
	    }
	    registerModeHandler(modeName, function(event : KeyboardEvent):Void {
	        handler(parentHandler, event);
	    });
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

        if (mode != 'default') {
            var modeHandler = getModeHandler( mode );
            (modeHandler || handleDefault)( event );
        }
        else {
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

                // go to the beginning of the Track and erase playback progress
                case Backspace:
                    p.startOver();

                // remove current track from queue
                case LetterX if ( event.noMods ):
                    var ct = sess.focusedTrack;
                    if (ct != null) {
                        p.gotoByOffset( 1 );
                        sess.removeItem( ct );
                    }

                // jump to time
                case LetterG if (event.metaKey || event.ctrlKey):
                    var jp = new TimeJumpPrompt();
                    jp.readTime( p );

                // copy
                case LetterC if (event.metaKey || event.ctrlKey):
                    //TODO copy
                    Clip;

                // paste
                case LetterV if (event.metaKey || event.ctrlKey):
                    //TODO paste

                case LetterX if (event.metaKey || event.ctrlKey):
                    //TODO cut

                // create [x] hotkey
                case LetterC if ( event.noMods ):
                    // next key
                    nextKeyDown(function(event : KeyboardEvent) {
                        switch ( event.key ) {
                            // create Mark
                            case LetterM:
                                defer(function() {
                                    p.addBookmark();
                                });
                            
                            // create Tab
                            case LetterT:
                                sess.setTab(sess.newTab());

                            default:
                                handleDefault( event );
                        }
                    });

                // jump to a random time in the track
                case LetterR if ( event.noMods ):
                    onDoubleTap(fn(_.noMods), function(dblTapped) {
                        if ( dblTapped ) {
                            var r = new Random();
                            p.currentTime = r.randfloat(0.0, p.durationTime);
                        }
                        else {
                            trace('you pressed the R key');
                        }
                    });

                // jump to a random Track in the Playlist
                case LetterR if ( event.shiftKey ):
                    onDoubleTap(fn(_.shiftKey), function( didit ) {
                        if ( didit ) {
                            var r = new Random();
                            p.gotoTrack(r.randint(0, p.session.playlist.length));
                        }
                        else {
                            //
                        }
                    });
                
                // toggle shuffle
                case LetterS if ( event.shiftKey ):
                    p.shuffle = !p.shuffle;
                    p.dispatch('toggle-shuffle', null);

                // capture snapshot
                case LetterS if ( event.noMods ):
                    onDoubleTap(fn(_.noMods), function( didit ) {
                        if ( didit ) {
                            p.snapshot();
                        }
                    });

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

                // Control+Shift+=
                case Equals if (event.shiftKey && event.ctrlKey):
                    p.scale += 0.01;

                // =
                case Equals if (event.noMods):
                    onDoubleTap(fn(_.key == Equals && _.noMods), function(didit) {
                        if ( didit ) {
                            p.scale = 1.0;
                        }
                        else {
                            p.playbackRate = 1.0;
                        }
                    });

                case Minus:
                    if ( event.ctrlKey ) {
                        p.scale -= 0.01;
                    }

                // M
                case LetterM:
                    if ( event.ctrlKey ) {
                        p.addBookmark();
                    }
                    else {
                        p.muted = !p.muted;
                    }

                // S
                case LetterS if ( event.shiftKey ):
                    p.snapshot();

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
                case LetterB:
                    // initiate that shit
                    p.view.controls.seekBar.bookmarkNavigation();

                // :
                case SemiColon if ( event.shiftKey ):
                    //TODO move this action into its own method associated with Player
                    defer(function() {
                        p.terminal();
                    });

                // `
                case BackTick:
                    defer(function() {
                        p.terminal();
                    });

                // ctrl+t
                case LetterT if (event.ctrlKey || event.metaKey):
                    if ( event.shiftKey ) {
                        p.tdfprompt(function(?error) {
                            if (error != null)
                                throw error;
                        });
                    }
                    else {
                        sess.setTab(sess.newTab());
                    }

            /* --- 'next-command-count' modifiers --- */

                // number 0
                case Number0, Numpad0:
                    mncc( 0 );

                // number 1
                case Number1, Numpad1:
                    numkey(1, event);

                // number 2
                case Number2, Numpad2:
                    numkey(2, event);

                // number 3
                case Number3, Numpad3:
                    numkey(3, event);

                // number 4
                case Number4, Numpad4:
                    numkey(4, event);

                // number 5
                case Number5, Numpad5:
                    numkey(5, event);

                // number 6
                case Number6, Numpad6:
                    numkey(6, event);

                // number 7
                case Number7, Numpad7:
                    numkey(7, event);

                // number 8
                case Number8, Numpad8:
                    numkey(8, event);

                // number 9
                case Number9, Numpad9:
                    numkey(9, event);

                default:
                    null;
            }
        }
	}

    /**
      * handle the typing of a numeric key
      */
	private function numkey(n:Int, e:KeyboardEvent):Void {
        if ( e.altKey ) {
            sess.setTab(n - 1);
        }
        else {
            mncc( n );
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
      * 
      */
    private function nextWithin(check:KeyboardEvent->Bool, maxDelay:Float, action:Bool->Void):Void {
        var called:Bool = false;
        function _handler(event : KeyboardEvent):Void {
            if (check( event )) {
                if ( !called ) {
                    action( true );
                    called = true;
                }
                _nextKeyDown.remove( _handler );
            }
            else if ( !called ) {
                action( false );
                called = true;
            }
        }
        nextKeyDown( _handler );
        wait(ceil( maxDelay ), function() {
            _nextKeyDown.remove( _handler );
            if ( !called ) {
                action( false );
                called = true;
            }
        });
    }

    /**
      * handle double-taps of keys
      */
    private function onDoubleTap(check:KeyboardEvent->Bool, action:Bool->Void):Void {
        nextWithin(check, 350, action);
    }

	/**
	  * get the seek time delta from the given Event
	  */
	private function seekTimeDelta(event : KeyboardEvent):Float {
		var n:Float = 0;
		// frame-by-frame mode
		if ( event.altKey ) {
		    var bn:Float = (1.0 / 30);
		    n = frameTimeDelta();
		    
			if ( event.shiftKey ) {
			    n *= 5.0;
			}
			else {
				n /= 3.0;
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

	private function frameTimeDelta():Float {
	    if (p.track != null && p.track.data != null && p.track.data.meta != null) {
	        var tuple = p.track.data.meta.getVideoFrameRateInfo();
	        if (tuple != null) {
	            return (tuple._1 / tuple._0);
	        }
	    }
	    return (1.0 / 30.0);
	}

	/**
	  * get the nextCommandCount
	  */
	public inline function getNextCmdCount():Int return nextCmdCount;

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

/* === Computed Instance Fields === */

    // shorthand reference to the Player
	private var p(get, never):Player;
	private inline function get_p():Player return app.player;

    // shorthand reference to the Session
	private var sess(get, never):PlayerSession;
	private inline function get_sess():PlayerSession return p.session;

/* === Instance Fields === */

	public var app : BPlayerMain;
	public var mode : String = 'default';
	public var modeHandlers : Dict<String, KeyboardEvent->Void>;

    private var _nextKeyDown:Array<KeyboardEvent->Void>;
    private var _nextKeyUp:Array<KeyboardEvent->Void>;
	private var nextCmdCount : Int;
	private var hkc : HotkeyController;

	//private var commands : Map<String, Void->Void>;
}
