package pman.ui;

import foundation.*;

import tannus.chrome.FileSystem;

import tannus.html.Element;
import tannus.ds.Memory;
import tannus.events.*;
import tannus.events.Key;

import pman.core.*;

import Std.*;
import electron.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;

class AutoCompletePrompt extends PromptBox {
    /* Constructor Function */
    public function new():Void {
        super();

        var auto = input.el.method( 'autocomplete' );
        auto({
            source: function(req, res) {
                request_options(req.term, res);
            },
            select: function(event, ui) {
                defer(function() {
                    line( ui.item.label );
                });
            }
        });
    }

/* === Instance Methods === */

    /**
      * get the autocomplete suggestions
      */
    public function request_options(text:String, yield:Dynamic->Void):Void {
        _request_options(text, function(result : Dynamic) {
            if (result == null) {
                result = [];
            }
            yield( result );
        });
    }

    private function _request_options(term:String, yield:Dynamic->Void):Void {
        yield( null );
    }

/* === Instance Fields === */

/* === Static Methods === */

    public static inline function create(o : FacpOpts):AutoCompletePrompt {
        return new Facp( o );
    }
}

private class Facp extends AutoCompletePrompt {
    private var _ro:String->(Dynamic->Void)->Void;
    public function new(o : FacpOpts):Void {
        super();

        _ro = o.source;
    }

    override function _request_options(t, y) _ro(t, y);
}

typedef FacpOpts = {
    source: String->(Dynamic->Void)->Void
}
