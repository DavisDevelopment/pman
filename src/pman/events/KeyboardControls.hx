package pman.events;

import tannus.ds.Dict;
import tannus.ds.Set;
import tannus.ds.Maybe;
import tannus.events.Key;
import tannus.math.Random;
import tannus.media.Duration;
import tannus.math.Time;

//import tannus.events.*;

//import gryffin.Tools.*;

import pman.core.*;
import pman.format.pmsh.*;
import pman.pmbash.*;
import pman.ui.*;
import pman.events.*;
import pman.sid.Clipboard as Clip;
import pman.async.tasks.*;

//import electron.ext.*;
//import electron.ext.GlobalShortcut in Gs;
//import electron.Tools.defer;

import tannus.html.Win;
import js.html.KeyboardEvent as NativeKbEvent;

import haxe.Constraints.Function;
import haxe.extern.EitherType as Either;

import Std.*;
import tannus.math.TMath.*;
import Slambda.fn;
import edis.Globals.*;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.FunctionTools;
using tannus.ds.AnonTools;
using tannus.math.TMath;

/**
  models the system through which keyboard-input is (or isn't) interpreted to control the application
 **/
class KeyboardControls {
    /* Constructor Function */
    public function new():Void {
        //super();

        modeHandlers = new Map();
        //sequence_map = new Array();
        nextCount = 1;
        cnku = new Set();

        var dm = createMode('default', {
            down: defaultKeyDown,
            up: defaultKeyUp
        });

        createMode('noop', {
            down: (m, e) -> null,
            up: (m, e) -> null
        });

        mode = 'default';

        if (instance == null) {
            instance = this;
        }
        else {
            throw 'Error: Only 1 instance of KeyboardControls can be created at a time';
        }
    }

/* === Instance Methods === */

    /**
      event-processor for <S-[x]> keycommands
     **/
    function s_cmd(m:KbCtrlModeHandler, event:KeyboardEvent) {
        leaveModeSubcategory();
        switch ( event.key ) {
            case LetterS:
                player.snapshot();

            case _:
                return ;
        }
    }

    /**
      event-processor for <C - [x]> keycommands
     **/
    function c_cmd(m:KbCtrlModeHandler, event:KeyboardEvent) {
        leaveModeSubcategory();
        switch event.key {
            /* create mark */
            case LetterM:
                player.addBookmark();
                cancelNextKeyUp(LetterM);

            case _:
                return ;
        }
    }

    /**
      event-processor for <= - [x]> keycommands
     **/
    function eq_cmd(m:KbCtrlModeHandler, event:KeyboardEvent) {
        leaveModeSubcategory();
        switch event.key {
            case Equals:
                player.scale = 1.0;

            case _:
                return ;
        }
    }

    @:access(pman.media.Track)
    function d_cmd(m:KbCtrlModeHandler, event:KeyboardEvent) {
        leaveModeSubcategory();

        function _callback(?error: Dynamic) {
            if (error != null)
                report(error);
        }

        switch event.key {
            case LetterD:
                if (player.track != null) {
                    player.track._delete( _callback );
                }

            case _:
                _callback();
        }
    }

    /**
      the default event listener for 'keydown' events
     **/
    private function defaultKeyDown(m:KbCtrlModeHandler, event:KeyboardEvent):Void {
        //trace('Key(${event.keyCode}): "${event.key}" pressed');

        switch ( event.key ) {
            /* Toggle Playback */
            case Space:
                player.togglePlayback();

            /* Skip to Next Track */
            case LetterN, NumpadPlus:
                player.gotoByOffset( 1 );

            /* "Previous" Actions (Return to beginning of media, or go to previous media) */
            case LetterP, NumpadMinus:
                /* return to previous track no matter what */
                if ( event.shiftKey ) {
                    player.gotoByOffset( -1 );
                }
                else {
                    //TODO incorporate 'fncc'
                    player.gotoPrevious();
                }

            /* Return to Track's Beginning, and delete stored playback-progress */
            case Backspace:
                player.startOver();

            /* Remove Current Track from Queue and Skip to the Next One */
            /* TODO move this (and other multi-step tasks) to a class devoted to things like this */
            case LetterX:
                // when (only when) there are no modifier-keys pressed
                if ( event.noMods ) {
                    if (player.track != null) {
                        var t = player.track;
                        player.gotoByOffset( 1 );
                        player.session.removeItem( t );
                    }
                }

            /* Perform Time-Jump */
            case LetterG:
                if ( event.ctrlOrMeta ) {
                    (new TimeJumpPrompt()).readTime( player );
                }

            /* Clipboard-Paste Controls */
            case LetterV:
                if ( event.ctrlOrMeta ) {
                    var formats = Clip.availableFormats();
                    if (formats.has('text/plain')) {
                        var data = Clip.readText();
                        HandleClipboardPaste.handle( data );
                    }
                }

            /* C...<next-key> Combos */
            case LetterC:
                /* capture next key */
                enterModeSubcategory('c')
                .nextKeyDown(function(m, event) {
                    /* C key was pressed alone */
                    if (m.isTimedOut()) {
                        m._default( event );
                    }
                    /* next key after C has been captured */
                    else {
                        c_cmd(m, event);
                    }
                });

            /* d combos */
            case LetterD:
                enterModeSubcategory('d')
                .nextKeyDown(function(m, event) {
                    if (m.isTimedOut()) {
                        return ;
                    }
                    else {
                        d_cmd(m, event);
                    }
                });

            /* S...<next-key> combos */
            case LetterS:
                /* when <shift> key is pressed with S */
                if ( event.shiftKey ) {
                    player.snapshot();
                }
                else if ( event.noMods ) {
                    /* net the next KeyDown event */
                    enterModeSubcategory('S')
                    .nextKeyDown(function(m, event) {
                        s_cmd(m, event);
                    });
                }

            /* toggle visibility of ui controls */
            case LetterH:
                player.view.controls.uiEnabled = !player.view.controls.uiEnabled;

            /* jump forward in timeline */
            case Right:
                player.currentTime += seekTimeDelta( event );

            /* jump backward in timeline */
            case Left:
                player.currentTime += -seekTimeDelta( event );

            case LetterE:
                player.currentTime += frameTimeDelta( event );

            /* increase volume */
            case Up:
                player.volume += volumeDelta( event );

            /* decrease volume */
            case Down:
                player.volume += -volumeDelta( event );

            /* increase playback speed */
            case CloseBracket:
                player.playbackRate += (flushNextCount() * 0.02);

            /* decrease playback speed */
            case OpenBracket:
                player.playbackRate -= (flushNextCount() * 0.02);

            /* <= ... [key]> combos */
            case Equals:
                enterModeSubcategory('=')
                .nextKeyDown(function(m, evt) {
                    if (m.isTimedOut()) {
                        player.playbackRate = 0.0;
                    }
                    else {
                        eq_cmd(m, evt);
                    }
                });

            /* M Key */
            case LetterM:
                /* Create and Add Bookmark */
                if ( event.ctrlKey ) {
                    player.addBookmark();
                }
                /* Toggle [muted] */
                else {
                    player.muted = !player.muted;
                }

            /* Toggle the Favorited Status of Current Track */
            case NumpadAsterisk:
                if (player.track != null) {
                    player.track.toggleStarred();
                }
            case Number8 if ( event.shiftKey ):
                if (player.track != null) {
                    player.track.toggleStarred();
                }

            /* Bookmark Navigation */
            case LetterB:
                if ( event.noMods ) {
                    player.view.controls.seekBar.bookmarkNavigation();
                }

            /* PmBash Terminal Widget */
            case SemiColon:
                if ( event.shiftKey ) {
                    /* create empty function */
                    var catchColonUp = (function(m, e) null);

                    /* override it with new, useful one */
                    catchColonUp = (function(m, evt:KeyboardEvent) {
                        // if [evt] is the release of the ';' key
                        if (evt.key == SemiColon) {
                            evt.preventDefault();
                            player.terminal();
                            //defer(player.terminal.bind());
                        }
                        else {
                            nextKeyUp(catchColonUp);
                        }
                    });
                    nextKeyUp( catchColonUp );
                }

            /* Fuzzy-Find Widget Trigger */
            case ForwardSlash:
                trace('Trigger: FuzzyFind');

            /* T key */
            case LetterT:
                /* Create new Tab */
                if ( event.ctrlKey ) {
                    player.session.setTab(player.session.newTab());
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

            // numpad . key
            case NumpadDot:
                if (nextCount > 1) {
                    var locked = nextCountLocked;
                    lockNextCount( !nextCountLocked );
                    if ( locked )
                        flushNextCount();
                }

            case _:
                trace('Unhandled KeyDown(${event.key})');
        }
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
	  * get the seek time delta from the given Event
	  */
	private function seekTimeDelta(event : KeyboardEvent):Float {
		var n:Float = 0;
		// frame-by-frame mode
		if ( event.altKey ) {
		    var bn:Float = (1.0 / 30);
		    n = frameTimeCoefficient();
		    
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

		n = (n * flushNextCount());
		return n;
	}

	/**
	  calculate or approximate the amount of time (in seconds) to move per frame
	 **/
	private function frameTimeCoefficient():Float {
	    if (player.track != null && player.track.data != null && player.track.data.meta != null) {
	        var tuple = player.track.data.meta.getVideoFrameRateInfo();
	        if (tuple != null) {
	            return (tuple._1 / tuple._0);
	        }
	    }
	    return (1.0 / 30.0);
	}

	/**
	  calculate the amount of time by which to move for the given Keyboard event
	 **/
	function frameTimeDelta(e: KeyboardEvent):Float {
	    return (frameTimeCoefficient() * flushNextCount() * (e.altKey ? -1 : 1));
	}

    /**
      the default event listener for 'keyup' events
     **/
    private function defaultKeyUp(m:KbCtrlModeHandler, event:KeyboardEvent):Void {
        if (cnku.exists( event.key )) {
            event.preventDefault();
            cnku.remove( event.key );
        }
        else {
            //
        }
    }

    /**
      schedule the .preventDefault() of the next 'keyup' event of a given type
     **/
    private function cancelNextKeyUp(key: Key):KeyboardControls {
        cnku.push( key );
        return this;
    }

    private function numkey(n:Int, e:KeyboardEvent) {
        if ( e.altKey ) {
            player.session.setTab(n - 1);
        }
        else {
            appendToNextCount( n );
        }
    }

    private function appendToNextCount(n: Int):Int {
        if ( nextCountLocked )
            return nextCount;
        else
            return nextCount = ((nextCount * 10) + n);
    }
    private inline function mncc(n: Int):Int return appendToNextCount(n);
    private inline function lockNextCount(locked:Bool=true):Bool return (nextCountLocked = locked);
    public function flushNextCount():Int {
        if (nextCountLocked) return nextCount;
        var ret = nextCount;
        nextCount = 1;
        return ret;
    }
    public function getNextCount():Int return nextCount;

    /**
      bind [this] to keyboard events
     **/
    public function bind() {
        if (__bound_hke == null) {
            //__bound_hke = this.handleKeyEvent.bind();
            __bound_hke = _hke_( this );
        }

        var target = Win.current;
        target.addEventListener('keydown', __bound_hke);
        target.addEventListener('keyup', __bound_hke);
    }

    /**
      unbind [this] from keyboard events
     **/
    public function unbind() {
        if (__bound_hke != null) {
            var target = Win.current;
            target.removeEventListener('keydown', __bound_hke);
            target.removeEventListener('keyup', __bound_hke);

            __bound_hke = null;
        }
    }

    private static function _hke_(c: KeyboardControls):NativeKbEvent->Void {
        return (function(e: NativeKbEvent) {
            c.handleKeyEvent(KeyboardEvent.fromNative( e ));
        });
    }

    /**
      artificially push KeyboardEvent onto [this]'s handling queue
     **/
    public function giveEvent(e:KeyboardEvent, ?mode:String) {
        var tmp = this.mode;
        if (mode != null)
            this.mode = mode;
        handleKeyEvent( e );
        this.mode = tmp;
    }

    /**
      net and handle the next 'keydown' event
     **/
    public function nextKeyDown(f: KbCtrlModeHandler -> KeyboardEvent -> Void, ?timeout:Int) {
        mh.catchDown( f );
    }

    /**
      net and handle the next keyup event
     **/
    public function nextKeyUp(f: KbCtrlModeHandler -> KeyboardEvent -> Void, ?timeout:Int) {
        mh.catchUp( f );
    }

    /* clear next-nets */
    public function clearNextKeyNet(?type: KeyPressType) {
        return mh.clearNet( type );
    }

    /**
      create, configure and return a new ModeHandler
     **/
    public function createMode(id:String, ?parentId:String, opts:KbCtrlModeHandlerOpts) {
        opts.id = id;
        if (parentId == null && id != 'default')
            parentId = 'default';
        else if (parentId == '')
            parentId = null;
        opts.parent = parentId;
        //TODO..?

        var modeCtrl = new KbCtrlModeHandler(this, opts);
        modeHandlers[id] = modeCtrl;
        return modeCtrl;
    }

    /**
      wrap the declaration of one mode around another
     **/
    public function wrapMode(id:String, newId:String, o:KCMWrapDef):KbCtrlModeHandler {
        if (!modeHandlers.exists( id )) {
            throw 'meh';
        }
        var m = getModeCtrl( id ).wrap(newId, o);
        return modeHandlers[newId] = m;
    }

    /* delete a ModeHandler */
    public function deleteMode(id: String):Bool return modeHandlers.remove( id );

    /* check for existence of a ModeHandler with the given id */
    public function hasMode(id: String):Bool return modeHandlers.exists( id );

    /**
      obtain reference to the ModeHandler registered under the given id
     **/
    public function getModeCtrl(id: String):Null<KbCtrlModeHandler> {
        return modeHandlers[id];
    }

    /**
      enter into a named mode subcategory
     **/
    public function enterModeSubcategory(id: String):KeyboardControls {
        controlModeSubcategory = id;
        return this;
    }

    /**
      exit the named mode subcategory, if any
     **/
    public function leaveModeSubcategory():KeyboardControls {
        controlModeSubcategory = null;
        return this;
    }

    /**
      get the name of the mode subcategory, if any
     **/
    public function modeSub():Null<String> {
        return controlModeSubcategory;
    }

    /**
      central handling/routing of KeyboardEvents
     **/
    private function handleKeyEvent(event: KeyboardEvent):Void {
        // determine KeyPressType
        var type:KeyPressType;
        switch (Std.string(event.type).toLowerCase()) {
            case 'keydown':
                type = KeyDown;

            case 'keyup': 
                type = KeyUp;

            case _:
                type = KeyDown;
                return ;
        }

        // sanity check -- ensure that there even is a handler for the declared mode
        if (!modeHandlers.exists( mode )) {
            throw 'invalid key-controls mode "$mode", sha';
        }

        //var handler:KbCtrlModeHandler = modeHandlers[mode];
        modeHandlers[mode].handle(type, event);
    }

/* === Computed Instance Fields === */

    private var mh(get, never): KbCtrlModeHandler;
    private inline function get_mh() return modeHandlers[mode];

/* === Instance Fields === */

    //var nextDown: Array<Function>;
    //var nextUp: Array<Function>;
    var modeHandlers: Map<String, KbCtrlModeHandler>;
    var __bound_hke:Null<NativeKbEvent->Void> = null;

    var nextCount: Int = 1;
    var nextCountLocked: Bool = false;

    var controlModeSubcategory:Null<String> = null;
    var cnku:Set<Key>;

    public var mode: String;

    static var instance:Null<KeyboardControls> = null;
    static var COMBO_WAIT_TIME:Int = 600;
}

/**
  purpose of class
 **/
@:access( pman.events.KeyboardControls )
class KbCtrlModeHandler {
    /* Constructor Function */
    public function new(ctrl:KeyboardControls, o:KbCtrlModeHandlerOpts):Void {
        k = ctrl;
        this.o = o;
        this.name = o.id;
        parentHandler = null;
        middles = [[], []];
        nextDown = null;
        nextUp = null;

        if (o.parent != null) {
            if ((o.parent is KbCtrlModeHandler))
                parentHandler = cast o.parent;
            else if ((o.parent is String))
                parentHandler = k.modeHandlers[cast o.parent];
        }

        scope_state = {
            handle: false,
            body: false,
            net: false
        };
        timed_out = false;
    }

/* === Instance Methods === */

    public dynamic function _super(event: KeyboardEvent):Void {
        if (parentHandler == null) {
            throw 'TypeError: [super] cannot be called on a root-level ModeHandler';
        }
        else if (notHandling()) {
            throw 'ScopeError: [super] cannot be called outside of the `handle` method';
        }
    }

    public dynamic function _default(event: KeyboardEvent):Void {
        if (notHandling()) {
            throw 'ScopeError: [default] cannot be called outside of the `handle` method';
        }
    }

    public dynamic function cancel():Void {
        if (notHandling()) {
            throw 'ScopeError: [cancel] cannot be called outside of the `handle` method';
        }
    }

    public function handleKeyDown(event: KeyboardEvent):Void {
        handle(KeyDown, event);
    }

    public function handleKeyUp(event: KeyboardEvent):Void {
        handle(KeyUp, event);
    }



    /**
      hand an event to [this] ModeHandler to process
     **/
    public function handle(pressType:KeyPressType, event:KeyboardEvent, forceDefault:Bool=false):Void {
        // create cache of scoped-method states to restore later
        var _tmpf = {
            _super: this._super,
            _default: this._default,
            cancel: this.cancel

            //_scope_: scope_state.deepCopy(true)
        };

        // set [this]'s scope-state
        scope_state.handle = true;

        // make function to reset cached methods
        function _freset() {
            this._super = _tmpf._super;
            this._default = _tmpf._default;
            this.cancel = _tmpf.cancel;
            //this.scope_state = _tmpf._scope_;
        }

        if (parentHandler != null) {
            _super = (e -> parentHandler.handle(pressType, e));
        }

        var _stop_ = {stop : true};
        _default = (function(e) {
            handle(pressType, e, true);
            //_freset
        });

        // check for 'net' function
        var net = getNet(pressType);

        // if there's a net, then it will catch the event before it flies further
        if (net != null && !forceDefault) {
            /**
              nullify the relevant 'net' property
              this is done BEFORE calling that function so that a new 'net' function can 
              be bound from within the current one and that'll work as expected
             **/
            setNet(pressType, null);

            // update scope-state
            //var _ssn = scope_state.net;
            //scope_state.net = true;

            // invoke the net
            net(this, event);
            //scope_state.net = _ssn;
        }
        else {
            // variables that track synchronous cancellation of event propogation
            var cancelled = false;

            // override [cancel]
            cancel = (function() {
                cancelled = true;
                //
                throw _stop_;
            });

            // handle "middleware" methods
            try {
                var mwa = middles[pressType.getIndex()];
                if (mwa == null)
                    throw '[wtf]';
                var mwerrs = [];
                for (mw in mwa) {
                    try {
                        mw(this, event);
                        mwerrs.push(null);
                    }
                    catch (e: Dynamic) {
                        if (e == _stop_) {
                            throw e;
                        }
                        else
                            mwerrs.push(e);
                    }
                }
                if (!mwerrs.empty())
                    throw mwerrs;
            }
            catch (err: Array<Dynamic>) {
                if (err.empty()) {
                    warn('Empty Array was thrown as error in KbCtrlModeHandler');
                }
                else {
                    warn( err );
                }
            }
            catch (err: Dynamic) {
                if (err == _stop_) {
                    trace('event-handling cancelled from within middleware');
                }
                else {
                    warn( err );
                }
            }

            // account for cancelation
            if ( cancelled ) {
                //_freset();
                //return ;
            }

            // get reference to the primary handler method
            var body = getF(pressType);

            if ( !cancelled ) {
                if (body != null) {
                    try {
                        //var _ssb = scope_state.body;
                        //scope_state.body = true;
                        body(this, event);
                        //scope_state.body = _ssb;
                    }
                    catch (err: Dynamic) {
                        if (err == _stop_) {
                            null;
                        }
                        else {
                            //_super = _os;
                            _freset();
                            throw err;
                        }
                    }
                }
                else {
                    _super( event );
                }
            }
        }

        _freset();
    }

    /**
      internal method for checking on scope-information
     **/
    function checkScope(in_handle:Bool=true, ?name:String):Bool {
        if (scope_state.handle == in_handle) {
            switch ( name ) {
                case null:
                    return true;

                case 'net':
                    return scope_state.net;

                case 'body','default':
                    return scope_state.body;

                default:
                    throw '"$name" is not a valid scope-assertion id';
            }
        }
        else return false;
    }
    inline function isHandling(?subscope_id: String):Bool {
        //return checkScope( subscope_id );
        return true;
    }
    inline function notHandling():Bool {
        //return checkScope(false);
        return false;
    }

    /**
      'use' one or both 'middleware' functions given
     **/
    public function use(?down:KbCtrlModeHandler->KeyboardEvent->Void, ?up:KbCtrlModeHandler->KeyboardEvent->Void):KbCtrlModeHandler {
        if (down != null)
            middles[0].push(down);
        if (up != null)
            middles[1].push(up);
        return this;
    }

    public inline function isTimedOut():Bool {
        //return timed_out;
        return false;
    }

    /**
      create and assign a new "net" method
     **/
    public function catchNext(pressType:KeyPressType, newNet:KbCtrlModeHandler->KeyboardEvent->Void):Void {
        var enet = getNet( pressType ), nnet = newNet;

        /* instantiate and enforce timeout */
        // for now, this code shall not be used, but will be preserved
        /*
        if (timeout_ms != null) {
            var timedOut:Bool = false, invoked:Bool = false;
            nnet = nnet.wrap(function(_, m, e) {
                var _to = this.timed_out;
                this.timed_out = timedOut;
                _(m, e);
                this.timed_out = _to;
                invoked = true;
            }).once();

            wait(timeout_ms, function() {
                timedOut = true;
                if (!invoked) {
                    nnet(this, new KeyboardEvent('keyup', -1, null));
                }
            });
        }
        */

        if (enet != null) {
            nnet = enet.join(nnet);
        }

        setNet(pressType, nnet);
    }

    public function catchDown(net: KbCtrlModeHandler -> KeyboardEvent -> Void) {
        catchNext(KeyDown, net);
    }

    public function catchUp(net: KbCtrlModeHandler -> KeyboardEvent -> Void) {
        catchNext(KeyUp, net);
    }

    /**
      unset and delete 'net' methods
     **/
    public function clearNet(?type: KeyPressType):Void {
        if (type != null) {
            setNet(type, null);
        }
        else {
            nextDown = nextUp = null;
        }
    }

    /**
      'wrap' another mode-handler around [this] one
     **/
    public function wrap(id:String, options:KCMWrapDef):KbCtrlModeHandler {
        var d = o.down, u = o.up;
        if (d != null && options.down != null) {
            d = d.wrap( options.down );
        }

        if (u != null && options.up != null) {
            u = u.wrap( options.up );
        }

        return new KbCtrlModeHandler(k, {
            id: id,
            parent: null,
            down: d,
            up: u
        });
    }

    private function getNet(type: KeyPressType):Null<KbCtrlModeHandler -> KeyboardEvent -> Void> {
        return switch type {
            case KeyDown: nextDown;
            case KeyUp: nextUp;
            case _: null;
        };
    }
    
    private function getF(type: KeyPressType):Null<KbCtrlModeHandler -> KeyboardEvent -> Void> {
        return switch type {
            case KeyDown: o.down;
            case KeyUp: o.up;
            case _: null;
        };
    }

    private function setNet(type:KeyPressType, value:Null<KbCtrlModeHandler->KeyboardEvent->Void>):Null<KbCtrlModeHandler->KeyboardEvent->Void> {
        return switch type {
            case KeyDown: nextDown = value;
            case KeyUp: nextUp = value;
            case _: throw 'TypeError: Invalid KeyPressType';
        };
    }

/* === Computed Instance Fields === */
/* === Instance Fields === */

    public var name(default, null): String;
    
    var k: KeyboardControls;
    var o: KbCtrlModeHandlerOpts;
    var parentHandler: Null<KbCtrlModeHandler>;
    /*
       [middles] is structured: [
         keydown_middleware[],
         keyup_middleware[]
       ]
     */
    var middles: Array<Array<KbCtrlModeHandler -> KeyboardEvent -> Void>>;
    var nextDown: Null<KbCtrlModeHandler -> KeyboardEvent -> Void>;
    var nextUp: Null<KbCtrlModeHandler -> KeyboardEvent -> Void>;

    var scope_state:{handle:Bool,body:Bool,net:Bool};
    var timed_out: Bool = false;
    var disallow_combo:Bool = false;
}

typedef KbCtrlModeHandlerOpts = {
    ?id: String,
    ?down: KbCtrlModeHandler -> KeyboardEvent -> Void,
    ?up: KbCtrlModeHandler -> KeyboardEvent -> Void,
    ?parent: Either<String, KbCtrlModeHandler>
};

typedef KCMWrapDef = {
    ?down: (KbCtrlModeHandler -> KeyboardEvent -> Void)->KbCtrlModeHandler->KeyboardEvent->Void,
    ?up: (KbCtrlModeHandler -> KeyboardEvent -> Void)->KbCtrlModeHandler->KeyboardEvent->Void
};

typedef SeqInfo = {
    events: Array<KeyboardEvent>
};

enum KeyPressType {
    KeyDown;
    KeyUp;
}

//private typedef Emitter = {
    //function on<T>(k:String, f:T->Void):Void;
    //function once<T>(k:String, f:T->Void):Void;
    //function off(k:String, ?f:Dynamic->Void):Void;
//};

//typedef ModeHandler = {
    //down: KeyboardEvent->Void,
    //up: KeyboardEvent->Void
//};
