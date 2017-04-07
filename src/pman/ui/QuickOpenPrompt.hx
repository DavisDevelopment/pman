package pman.ui;

import foundation.*;

import tannus.chrome.FileSystem;

import tannus.html.Element;
import tannus.ds.Memory;
import tannus.events.*;
import tannus.events.Key;

import pman.core.*;
import pman.media.*;
import pman.db.*;
import pman.search.*;
import pman.search.QuickOpenItem;
import pman.search.QuickOpenItems;

import Std.*;
import electron.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;
using pman.media.MediaTools;
using pman.search.SearchTools;

class QuickOpenPrompt extends PromptBox {
    /* Constructor Function */
    public function new():Void {
        super();

        title = 'Quick Open';

        engine = new QoSearchEngine();
        engine.strictness = 3;
        engine.setContext([]);
    }

/* === Instance Methods === */

    public function init(done : Void->Void):Void {
        getitems(function() {
            setupAutocompletion();
            done();
        });
    }

    /**
      * await input
      */
    public function prompt(f : Void->Void):Void {
        readLine(function(line : Null<String>) {
            if (line != null) {
                engine.setSearch( line );
                var matches = engine.getMatches();
                trace( matches );
                close();
            }
        });
        open();
    }

    /**
      * configures the autocompletion
      */
    private function setupAutocompletion():Void {
        inline function item(ui : Dynamic):QuickOpenItem {
            return untyped ui.item;
        }
        inline function q(x:Dynamic):Element return new Element(x);
        var auto:Dynamic = input.el.method( 'autocomplete' );
        auto({
            source: engine.context,
            select: function(event, ui) {
                defer(function() {
                    line(item(ui).name());
                });
            },
            focus: function(event, ui) {
                defer(function() {
                    value = item(ui).name();
                });
            }
        });
        (auto('instance')._renderItem = function(ul:Element, item:QuickOpenItem) {

            var li = q('<li>');
            var row = q('<div>');
            row.addClass('quick-open-suggestion');
            row.html('${item.name()}');
            switch ( item ) {
                case QOMedia( src ):
                    null;

                case QOPlaylist( name ):
                    null;
            }
            row.plugin('tooltip');
            li.append( row );
            li.appendTo( ul );
            return li;

        });
    }

    private function getitems(f : Void->Void):Void {
        QuickOpenItems.get(function( items ) {
            engine.setContext( items );
            f();
        });
    }

/* === Instance Fields === */

    public var engine : QoSearchEngine;
}
