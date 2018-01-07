package pman.bg;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;
import tannus.async.*;
import tannus.math.*;
import tannus.internal.CompileTime as Ct;
import tannus.sys.Path;
import tannus.http.Url;

import edis.concurrency.*;

import hscript.*;
import hscript.plus.*;

import Slambda.fn;
import edis.Globals.*;
import tannus.math.TMath.*;

import pman.bg.media.*;
import pman.bg.db.*;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;
using pman.bg.MediaTools;
using tannus.async.Asyncs;

class BgTest extends Worker {
    /**
      * worker's execution starting point
      */
    override function __start() {
        super.__start();
        send('ready', 'Betty');

        db = new Database();
        db.init(function(?error) {
            if (error != null) {
                throw error;
            }
            else {
                trace('ready for whatever');
            }
        });

        // listen for packets on the 'exec' channel
        on('exec', function(packet) {
            decodePacket( packet );
        });
    }

    /**
      * process incoming 'media' packet
      */
    private function decodePacket(packet: WorkerIncomingPacket) {
        var ctx:Object = packet.data;
        inline function has(prop:String):Bool {
            return ctx.exists( prop ); 
        }

        // get the values of multiple properties of [ctx]
        function gets<T>(props: Array<String>):Array<Null<T>> {
            var results:Array<Null<T>> = new Array();
            for (prop in props) {
                if (has( prop )) {
                    results.push(ctx.get( prop ));
                }
            }
            return results;
        }

        // get the first property among a list of property-keys
        function getFirst<T>(props: Array<String>):Null<T> {
            for (prop in props) {
                if (has( prop )) {
                    return ctx.get( prop );
                }
            }
            return null;
        }

        // declare variables that will be used for every directive
        var keys:Array<String> = new Array();
        inline function key(x) keys.push(untyped x);
        function append(x: Array<Dynamic>) {
            keys = keys.concat(cast x).map(fn(_.trim().nullEmpty())).compact().unique();
        }

        var cmd:String = 'media:get';
        var options : CmdOptions;

        if ((ctx is String)) {
            keys.push( ctx );
        }
        else if (Reflect.isObject( ctx )) {
            var ka:Null<String> = getFirst(['key', 'uri', 'id']);
            if (ka != null)
                key( ka );

            var aka:Array<Null<Array<Null<String> >>> = gets(['keys', 'uris', 'ids']).map(function(a: Array<Null<String>>) {
                return a.map(s -> s.nullEmpty()).compact().nullEmpty();
            });
            var ka:Array<String> = aka.flatten().compact().nullEmpty();
            if (ka != null) {
                append( ka );
            }
            
            var ncmd = getFirst(['cmd', 'command']);
            if (ncmd != null) {
                cmd = ncmd;
            }
        }
        else {
            raise('TypeError: Invalid type for [ctx]');
        }

        if (keys.empty()) {
            return raise('Error: No key provided');
        }

        // construct [options]
        options = {
            cmd: cmd,
            ids: new Array(),
            uris: new Array()
        };

        // sort [keys] into their respective properties of [options]
        for (key in keys) {
            (key.isUri() ? options.uris : options.ids).push( key );
        }

        trace('cmd: ${options.cmd}');
        trace('ids: [${options.ids.length}]');
        trace( options.ids );
        trace('uris: [${options.uris.length}]');
        trace( options.uris );

        // fetch MediaRow and Media objects, then execute the command
        [get_medias].map(x -> x.bind(options, _)).series(function(?error) {
            if (error != null) {
                return raise( error );
            }
            else {
                execCmd(options, packet);
            }
        });
    }

    /**
      * carry out the given Command
      */
    private function execCmd(o:CmdOptions, packet:WorkerIncomingPacket):Void {
        var dir = parse_directive( o.cmd );
        o.cmd = dir.join('.');
        if (!o.medias.hasContent()) {
            return raise('Error: No Medias to work with');
        }
        
        if (o.cmd == 'media.get') {
            var media = o.medias[0];
            media.data.setBeginTime( 35.0 );
            media.data.addTag( 'urinal' );
            media.data.save().then(function() {
                packet.reply(media.data.toRow(), 'haxe');
            });
        }
        else {
            raise('unhandled command ["${o.cmd}"]');
        }
    }

    /**
      * parse the textual representation of the command-directive
      */
    private function parse_directive(command: String) {
         var pattern:EReg = (~/([\u0009\u000A\u000B\u000C\u000D\u0020.:]+)/gi);
         var pieces:Array<String> = pattern.split( command ).map(x -> x.trim().nullEmpty()).compact();
         //TODO parse it further to allow for "flags" to be attached to each sub-command of the directive
         return pieces;
    }

    /**
      * get the Media objects for the given CmdOptions
      */
    private function get_medias(o:CmdOptions, done:VoidCb):Void {
        var medias:Array<Media> = new Array();
        var steps:Array<VoidAsync> = new Array();

        if (o.uris != null) {
            for (uri in o.uris) {
                steps.push(function(next) {
                    Media.get(uri, function(?error, ?media) {
                        if (error != null)
                            next( error );
                        else {
                            medias.push( media );
                            next();
                        }
                    });
                });
            }
        }

        steps.push(function(next) {
            o.medias = medias.compact().nullEmpty();
            next();
        });
        steps.series( done );
    }

    /**
      * fetch the MediaRows referenced by the given CmdOptions
      */
    private function get_rows(o:CmdOptions, done:VoidCb):Void {
        // handle the MediaRows once they're obtained
        function on_rows(rows: Array<MediaRow>) {
            //trace('loaded ${rows.length}/${o.keys.length} MediaRows');
            // if no rows were obtained
            if (rows.length == 0) {
                done();
            }
            else {
                o.rows = rows;
            }
            done();
        }

        // the steps to carry out and the array to store results in
        var steps:Array<VoidAsync> = new Array();
        var results:Array<MediaRow> = new Array();

        // add a MediaRow to the results list
        function add_row(nxt:VoidCb, ?error:Dynamic, ?row:MediaRow) {
            if (error != null) {
                nxt( error );
            }
            else {
                results.push( row );
            }
        }

        // handle uris
        if (o.uris != null) {
            for (uri in o.uris) {
                steps.push(function(next: VoidCb) {
                    db.media.getRowByUri(uri, add_row.bind(next, _, _));
                });
            }
        }
        
        // handle ids
        if (o.ids != null) {
            for (id in o.ids) {
                steps.push(function(next: VoidCb) {
                    db.media.getRowById(id, add_row.bind(next, _, _));
                });
            }
        }

        // carry out the steps
        steps.series(function(?error) {
            if (error != null) {
                return done( error );
            }
            else {
                on_rows(results.compact());
            }
        });
    }

    /**
      * report an error..
      */
    private inline function raise(error: Dynamic):Void {
        send('::exception::', error, 'haxe');
    }

/* === Instance Fields === */

    public var db: Database;
}

typedef CmdOptions = {
    cmd: String,
    //?key: String,
    //?keys: Array<String>,
    ?uris: Array<String>,
    ?ids: Array<String>,
    //?row: MediaRow,
    ?rows: Array<MediaRow>,
    //?media: Media,
    ?medias: Array<Media>
};

typedef Cmd = {
    text: String,
    directive: CmdDirective,
    arguments: Array<Dynamic>
};

class CmdDirective {
    public var name(default, null): String;
    public var pieces(default, null): Array<CmdDirectivePiece>;
    public var length(default, null): Int;
    
    public function new(name:String, pieces:Array<CmdDirectivePiece>) {
        this.name = name;
        this.pieces = pieces;
        this.length = pieces.length;
    }

    public function get(index: Either<Int, String>):CmdDirectivePiece {
        if ((index is String)) {
            return pieces.firstMatch(x->(x.name == (cast index)));
        }
        else {
            return pieces[cast index];
        }
    }

    public function iterator():Iterator<CmdDirectivePiece> {
        return pieces.iterator();
    }
}

class CmdDirectivePiece {
    public var name: String;
    public var flags: Set<String>;

    public function new(name:String, flags:Iterable<String>) {
        this.name = name;
        this.flags = new Set();
        this.flags.pushMany( flags );
    }

    public function hasFlag(n:String):Bool return flags.exists( n );
    public function addFlag(n: String):Void {
        n = n.trim();
        if (n.has( ',' )) {
            var a = n.split(',').map(s->s.nullEmpty()).compact();
            return flags.pushMany( a );
        }
        flags.push( n );
    }
}

