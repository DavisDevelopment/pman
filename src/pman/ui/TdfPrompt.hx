package pman.ui;

import foundation.*;

import tannus.chrome.FileSystem;

import tannus.html.Element;
import tannus.ds.Memory;
import tannus.events.*;
import tannus.events.Key;

import pman.core.*;
import pman.media.*;
import pman.media.info.*;
import pman.db.*;
import pman.async.*;
import pman.format.tdf.*;

import Std.*;
import electron.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;
using pman.media.MediaTools;
using pman.search.SearchTools;

class TdfPrompt extends PromptBox {
    private var player : Player;
    public function new(p : Player):Void {
        super();

        player = p;
        title = 'track tags';
    }

    public function prompt(done : VoidCb):Void {
        if (player.track == null)
            defer(done.void());
        readLine(function(line : Null<String>) {
            if (line == null) {
                close();
                return done();
            }
            else {
                var parser = new Parser();
                var tokens = parser.tokenizeString( line );
                trace(tokens+'');
                var expr = parser.parseTokens( tokens );
                trace(expr+'');
                parser.apply(expr, player.track, done);
            }
        });
        open();
    }
}
