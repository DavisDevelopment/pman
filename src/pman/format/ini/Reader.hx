package pman.format.ini;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.*;

import pman.core.*;
import pman.media.*;

import Slambda.fn;
import pman.format.ini.Data;
import pman.format.ini.Data.ININode;

using StringTools;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.ds.StringUtils;
using Slambda;
using pman.media.MediaTools;

class Reader {
    /* Constructor Function */
    public function new():Void {
        strict = true;
    }

    /* === Instance Methods === */

    /**
     * parse the given String into structured INI data
     */
    public inline function readString(s : String):INI return read(s.split( '\n' ));

    /**
     * read the given list of lines, and parse them into structured INI data
     */
    public function read(lines : Array<String>):INI {
        nodes = new Array();

        __parse( lines );

        return {
            nodes: nodes
        };
    }

    /**
     * parse the input lines into an array of nodes
     */
    private function __parse(lines : Array<String>):Void {
        var section:Null<Array<ININode>> = null;
        for (index in 0...lines.length) {
            var line:String = (lines[index].trim());

            if (line.empty()) {
                if ( strict ) {
                    throw 'ParsingError(INI): Line $index is empty. Correct this issue or disable the "strict" flag in the INI parser';
                }
                else {
                    trace('INI: line $index is blank');
                }
            }
            else if (line.startsWith(';') || line.startsWith('#')) {
                var node:ININode = INIComment(line.slice( 1 ));
                (section != null ? section : nodes).push( node );
            }
            else if (line.startsWith('[')) {
                var name = line.after('[').before(']');
                var body:Array<ININode> = new Array();
                var node:ININode = INISection(name, body);
                nodes.push( node );
                section = body;
            }
            else {
                var node:ININode = INIProp({
                    name: line.before('='),
                    value: line.after('=')
                });
                (section != null ? section : nodes).push( node );
            }
        }
    }

    //private inline function node(n : ININode):Void nodes.push( n );

    /* === Instance Fields === */

    public var strict : Bool;

    //private var lines : Array<String>;
    private var nodes : Array<ININode>;

    /* === Static Methods === */

    // shorthand function
    public static inline function run(lines : Array<String>):INI return (new Reader().read( lines ));
}
