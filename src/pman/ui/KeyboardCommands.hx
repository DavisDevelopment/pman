package pman.ui;

import tannus.events.*;
import tannus.events.Key;

import Std.*;
import tannus.math.TMath.*;
import gryffin.Tools.defer;

import pman.core.*;

import electron.ext.*;
import electron.ext.GlobalShortcut in Gs;

class KeyboardCommands {
	/* Constructor Function */
	public function new(app : BPlayerMain):Void {
		this.app = app;
		//commands = new Map();
	}

/* === Instance Methods === */

	/**
	  * bind all commands
	  */
	public function bind():Void {
		app.playerPage.stage.on('keydown', handleKeyDown);
	}

	/**
	  * unbind all commands
	  */
	public function unbind():Void {
		
	}

	private function handleKeyDown(event : KeyboardEvent):Void {
		switch ( event.key ) {
			// Space
			case Space:
				p.togglePlayback();

            // Backspace
			case Backspace:
			    // go forward
			    if ( event.shiftKey ) {
			        var possible = sess.history.canGoForward();
			        trace('it is ${possible?'':' not '} possible to go forward');
			        if ( possible ) {
			            trace('navigating forward');
			            sess.history.goForward();
			        }
			    }
			    // go backward
                else {
			        var possible = sess.history.canGoBack();
			        trace('it is ${possible?'':' not '} possible to go backward');
			        if ( possible ) {
			            trace('navigating backward');
			            sess.history.goBack();
			        }
                }

			// N
			case LetterN:
				//p.gotoNext();
				p.gotoByOffset(fncc());

			// P
			case LetterP:
				p.gotoPrevious();

			// X
			case LetterX:
			    var ct = sess.focusedTrack;
			    if (ct != null) {
			        p.gotoByOffset( 1 );
			        sess.playlist.remove( ct );
			    }

			// Ctrl+Shift+O
			case LetterO if ((event.ctrlKey || event.metaKey) && event.shiftKey):
				p.selectAndOpenAddresses();

			// Ctrl+O
			case LetterO if (event.ctrlKey || event.metaKey):
				p.selectAndOpenFiles();

			// Ctrl+F
			case LetterF if (event.ctrlKey || event.metaKey):
				p.selectAndOpenDirectory();

			// Ctrl+Q
			case LetterQ if (event.metaKey || event.ctrlKey):
				app.quit();

			// Ctrl+W
			case LetterW if (event.metaKey || event.ctrlKey):
				p.clearPlaylist();

			// Ctrl+R
			case LetterR if (event.metaKey || event.ctrlKey):
				app.browserWindow.webContents.reload();

			// Ctrl+Shift+J
			case LetterJ if (event.shiftKey && (event.metaKey || event.ctrlKey)):
				var wc = app.browserWindow.webContents;
				if (wc.isDevToolsOpened()) {
					wc.closeDevTools();
				}
				else {
					wc.openDevTools();
				}

			// Ctrl+S
			case LetterS if (event.metaKey || event.ctrlKey):
				//app.appDir.saveSession(p.session.toJson());
				p.saveState();

            // snapshot
			case LetterS if ( event.shiftKey ):
			    //TODO take a snapshot
			    p.snapshot();

            /*
               jump to the end of the current media, skipping to the next one,
               and resetting the info such that the media will start at the beginning
               the next time that it's played
            */
			case LetterG if ( event.shiftKey ):
			    if (sess.hasMedia()) {
			        var ct = sess.focusedTrack;
			        p.currentTime = p.durationTime;
			        p.gotoNext({
                        manipulate: function(mc) {
                            ct.getDbMediaInfo(p.app.db, function( info ) {
                                info.time.last = null;

                                info.push(function() null);
                            });
                        }
			        });
			    }

			case LetterL:
				p.togglePlaylist();

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
					//TODO mark current location in the current media
				}
				else {
					p.muted = !p.muted;
				}

		/* --- 'next-command-count' modifiers --- */

			case Number0:
				mncc( 0 );

			case Number1:
				mncc( 1 );

			case Number2:
				mncc( 2 );

			case Number3:
				mncc( 3 );

			case Number4:
				mncc( 4 );

			case Number5:
				mncc( 5 );

			case Number6:
				mncc( 6 );

			case Number7:
				mncc( 7 );

			case Number8:
				mncc( 8 );

			case Number9:
				mncc( 9 );

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

	private var nextCmdCount : Int;

	//private var commands : Map<String, Void->Void>;
}
