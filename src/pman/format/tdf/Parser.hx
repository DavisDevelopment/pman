package pman.format.tdf;

import tannus.io.*;
import tannus.ds.*;

import pman.core.*;
import pman.media.*;
import pman.media.info.*;
import pman.async.*;

import Slambda.fn;
import electron.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.async.Asyncs;
using pman.async.VoidAsyncs;

class Parser extends LexerBase {
    /* Constructor Function */
    public function new():Void {

    }

/* === Instance Methods === */

    /**
      * tokenize given buffer
      */
    public function tokenize(bytes : ByteArray):Array<Token> {
        buffer = new ByteStack( bytes );
        tokens = new Array();
        while (!done) {
            var nt = token();
            if (nt != null)
                tokens.push( nt );
        }
        return tokens;
    }
    public inline function tokenizeString(s : String):Array<Token> return tokenize(ByteArray.ofString( s ));
    public inline function parseString(s : String):Array<Expr> return parseTokens(tokenizeString( s ));

    /**
      * consume and return next Token
      */
    private function token():Null<Token> {
        if ( done )
            return null;
        else {
            var c = next();
            if (c.isWhiteSpace()) {
                advance();
                if (c.isLineBreaking()) {
                    return TDelimiter;
                }
                else return token();
            }
            else if (c.equalsChar('"') || c.equalsChar("'")) {
                var sd = advance();
                var str:String = readGroup(sd, sd, '\\'.code);
                return TConst(CString( str ));
            }
            else if (c.isAlphaNumeric()) {
                var ident:String = advance();
                while (!done && next().isAlphaNumeric()) {
                    ident += advance();
                }
                return TConst(CIdent( ident ));
            }
            else if (c.equalsChar('<')) {
                advance();
                return TOpenTag;
            }
            else if (c.equalsChar('>')) {
                advance();
                return TCloseTag;
            }
            else if (c.equalsChar('[')) {
                advance();
                return TOpenBox;
            }
            else if (c.equalsChar(']')) {
                advance();
                return TCloseBox;
            }
            else if (c.equalsChar(',')) {
                advance();
                return TDelimiter;
            }
            else if (c.equalsChar('+')) {
                advance();
                return TExtend;
            }
            else {
                throw 'SyntaxError: Unexpected "$c"';
            }
        }
    }

    /**
      * parse the given ByteArray
      */
    public function parseBytes(bytes : ByteArray):Array<Expr> {
        return parseTokens(tokenize( bytes ));
    }

    /**
      * parses the next expression
      */
    private function nextExpr(tokens:Stack<Token>):Null<Expr> {
        inline function done() return tokens.empty;
        inline function next() return tokens.peek();
        inline function advance() return tokens.pop();

        if (done()) {
            return null;
        }
        else {
            switch (next()) {
                case TDelimiter:
                    advance();
                    return nextExpr( tokens );

                case TConst(CIdent(name)), TConst(CString(name)):
                    advance();
                    return parseTag(name, tokens);

                case TOpenTag:
                    var tagExpr = parseTagGrouping( tokens );
                    if (tagExpr == null) {
                        throw 'SyntaxError: <...> group cannot be empty';
                    }
                    else if (!tagExpr.match(ETag(_,_))) {
                        throw 'SyntaxError: Unexpected ${tagExpr}';
                    }
                    else return tagExpr;

                default:
                    throw 'SyntaxError: Unexpected token ${next()}';
            }
        }
    }

    /**
      * parse out a tag expression
      */
    private function parseTag(name:String, tokens:Stack<Token>):Expr {
        inline function done() return tokens.empty;
        inline function next() return tokens.peek();
        inline function advance() return tokens.pop();

        if (done()) {
            return ETag(name, null);
        }
        else {
            switch (next()) {
                case TDelimiter:
                    advance();
                    while (!done() && next().equals(TDelimiter))
                        advance();
                    return ETag(name, null);

                case TOpenBox:
                    advance();
                    var box = parseBox( tokens );
                    return ETag(name, box);

                default:
                    throw 'SyntaxError: Unexpected token ${next()}';
            }
        }
    }

    /**
      * parse out [...] grouping
      */
    private function parseBox(tokens : Stack<Token>):Array<Expr> {
        inline function done() return tokens.empty;
        inline function next() return tokens.peek();
        inline function advance() return tokens.pop();

        var box:Array<Expr> = new Array();
        while (!done() && !next().equals(TCloseBox)) {
            switch (next()) {
                case TDelimiter:
                    advance();
                    while (!done() && next().equals(TDelimiter))
                        advance();
                    continue;

                case TConst(CIdent(name)), TConst(CString(name)):
                    advance();
                    box.push(EAlias( name ));

                case TExtend:
                    advance();
                    var dep = depExpr( tokens );
                    switch ( dep ) {
                        case ETag(name, depBox):
                            box.push(ESuper(name, depBox));
                            continue;

                        default:
                            throw 'SyntaxError: Unexpected $dep';
                    }

                default:
                    throw 'SyntaxError: Unexpected ${next()}';
            }
        }

        if (!done() && next().equals( TCloseBox )) {
            advance();
        }
        else {
            trace(next()+'');
        }
        
        return box;
    }

    /**
      * parses out a dependency-declaration expression
      */
    private function depExpr(tokens:Stack<Token>):Null<Expr> {
        inline function done() return tokens.empty;
        inline function next() return tokens.peek();
        inline function advance() return tokens.pop();

        if (done()) {
            return null;
        }
        else {
            switch (next()) {
                case TConst(CIdent(name)), TConst(CString(name)):
                    advance();
                    //return parseTag(name, tokens);
                    return ETag(name, null);

                case TOpenTag:
                    var tagExpr = parseTagGrouping( tokens );
                    if (tagExpr == null) {
                        throw 'SyntaxError: <...> group cannot be empty';
                    }
                    else if (!tagExpr.match(ETag(_,_))) {
                        throw 'SyntaxError: Unexpected ${tagExpr}';
                    }
                    else return tagExpr;

                default:
                    throw 'SyntaxError: Unexpected token ${next()}';
            }
        }
    }

    /**
      * parse out the contents of a '<...>' group
      */
    private function parseTagGrouping(tokens : Stack<Token>):Null<Expr> {
        inline function done() return tokens.empty;
        inline function next() return tokens.peek();
        inline function advance() return tokens.pop();

        if (done() || !next().equals(TOpenTag))
            return null;

        advance();
        var level:Int = 1;
        var tagTokens:Array<Token> = new Array();
        while (!done() && (level > 0)) {
            switch (next()) {
                case TOpenTag:
                    level++;

                case TCloseTag:
                    level--;

                default:
                    null;
            }
            tagTokens.push(advance());
            if (level == 0) {
                tagTokens.pop();
            }
        }
        var tagTree = subParse( tagTokens );
        return tagTree[0];
        if (tagTree.length > 1 || tagTree.length == 0) {
            throw 'What the fuck?';
        }
        else {
            return tagTree[0];
        }
    }

    /**
      * shorthand to create a new parser and parse the given tokens
      */
    private inline function subParse(toks : Array<Token>):Array<Expr> {
        return new Parser().parseTokens( toks );
    }

    /**
      * parse the given list of tokens
      */
    public function parseTokens(tokens : Array<Token>):Array<Expr> {
        tree = new Array();
        this.tokens = tokens;
        var tks = new Stack( tokens );
        while ( !tks.empty ) {
            var ne = nextExpr(tks);
            if (ne != null)
                tree.push( ne );
        }
        return tree;
    }

    /**
      * add the tags defined by [tree] to [track]
      */
    public function apply(etree:Array<Expr>, track:Track, done:VoidCb):Void {
        var steps:Array<VoidAsync> = new Array();
        steps.push(function(next) {
            track.getData(function(?error, ?data) next( error ));
        });
        for (expr in etree) {
            steps.push(function(next) {
                return next();
                //var tag = toTag( expr );
                //trace('validating tag..');
                //tag.sync(function(?error) {
                    //if (error != null) {
                        //return next( error );
                    //}
                    //trace( tag );
                    //track.data.attachTag( tag );
                    //tag.push(function(?error) {
                        //next( error );
                    //});
                //});
            });
        }
        steps.series( done );
    }

    /**
      * build Tag instance from expression
      */
    //private function toTag(e : Expr):Tag {
        //switch ( e ) {
            //case ETag(_.toLowerCase()=>name, box):
                //var tag = new Tag( name );
                //if (box != null) {
                    //for (be in box) {
                        //switch ( be ) {
                            //case EAlias(_.toLowerCase()=>aname):
                                //tag.aliases.push( aname );

                            //case ESuper(superName, superBox):
                                //var superTag = toTag(ETag(superName, superBox));
                                //tag.inherits( superTag );

                            //default:
                                //throw 'SyntaxError: Unexpected $be';
                        //}
                    //}
                //}
                //return tag;

            //default:
                //throw 'Error: Cannot cast $e to Tag';
        //}
    //}

/* === Instance Fields === */

    private var tokens : Array<Token>;
    private var tree : Array<Expr>;

/* === Static Methods === */

    public static inline function lex(bytes:ByteArray):Array<Token> return new Parser().tokenize( bytes );
    public static inline function lexString(s:String):Array<Token> return new Parser().tokenizeString( s );
}

enum Expr {
    ETag(name:String, ?box:Array<Expr>);

    EAlias(s : String);
    ESuper(name:String, ?box:Array<Expr>);
}

enum Token {
    TConst(c : Const);
    
    TOpenTag;
    TCloseTag;
    TOpenBox;
    TCloseBox;
    TDelimiter;
    TExtend;
}

enum Const {
    CIdent(ident : String);
    CString(str : String);
}
