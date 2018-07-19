package pman.ui;

import tannus.html.Element;
import tannus.ds.Memory;
import tannus.events.*;
import tannus.events.Key;

//import foundation.*;
import edis.dom.*;

import pman.core.*;
import pman.pmbash.*;
import pman.format.pmsh.*;
import pman.format.pmsh.Expr;
import pman.async.*;

import Std.*;
import haxe.ds.Either;
import edis.Globals.*;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;

/**
  widget that acts as the "terminal" input
 **/
class PMBashTerminal extends EdisDomComponentPromptBox {
    /* Constructor Function */
    public function new(player : Player):Void {
        super();

        addClass('pmbash');

        this.player = player;
    }

/* === Instance Methods === */

    /**
      * wait for valid pmsh input
      */
    public function readExpr(done : Cb<Expr>):Void {
        readLine(function(line : Null<String>):Void {
            var res = parse( line );
            switch ( res ) {
                case Result.Value( val ):
                    done(null, val);

                case Result.Error( err ):
                    done(err, null);
            }
        });
    }

    /**
      * attempt to parse the current input
      */
    public function parse(?line : String):Result<Dynamic, Null<Expr>> {
        if (line == null) {
            line = value;
        }
        if (line == null) {
            return Result.Value( null );
        }
        else {
            try {
                var expr = NewParser.runString( line );
                trace('' + expr);
                return Result.Value( expr );
            }
            catch (error : Dynamic) {
                return Result.Error( error );
            }
        }
    }

    /**
      * handle keyboard input
      */
    override function keyup(event : KeyboardEvent):Void {
        super.keyup( event );
        switch ( event.key ) {
            case Tab:
                event.preventDefault();
                autoComplete();

            default:
                null;
        }
    }

    /**
      * perform code completion
      */
    private function autoComplete():Void {
        // get results of 'parse'
        var pr = parse();
        switch ( pr ) {
            // parse error
            case Result.Error( error ):
                value = '';

            case Result.Value( expr ):
                if (expr == null) {
                    value = '';
                }
                else {
                    switch ( expr ) {
                        default:
                            return ;
                    }
                }
        }
    }

    override function open():Void {
        appendTo('body');
        //modal.open();
        __center();
    }

/* === Instance Fields === */

    public var player : Player;
}
