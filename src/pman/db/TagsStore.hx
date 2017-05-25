package pman.db;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.EitherType as Either;
import tannus.ds.promises.*;

import ida.*;
import ida.backend.idb.IDBCursorWalker in CursorWalker;

import pman.core.*;
import pman.media.*;
import pman.async.*;
import pman.media.info.Tag;

import js.Browser.console;
import Slambda.fn;
import tannus.math.TMath.*;
import electron.Tools.defer;
import haxe.extern.EitherType;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.async.VoidAsyncs;

class TagsStore extends TableWrapper {
    /* Constructor Function */
    public function new(dbr : PManDatabase):Void {
        super( dbr );
    }

/* === Instance Methods === */

    /**
      * write [row] onto the database
      */
    public function putTagRow(row : TagRow):Promise<TagRow> {
        return put('tags', row);
    }
    public function putTagRow_(row:TagRow, ?done:Cb<TagRow>):Void {
        if (done == null)
            done = untyped fn([e,v]=>null);
        putTagRow( row ).then(done.yield()).unless(done.raise());
    }
    public function addTag(tag:Tag, ?done:Cb<TagRow>):Void {
        putTagRow_(tag.toRow(), done);
    }
    public function add(name:String, ?type:TagType, ?done:Cb<TagRow>):Void {
        addTag(new Tag(name, null, type), done);
    }

    /**
      * retrieve a row from [this] table
      */
    public function getTagRow(id : Int):Promise<Null<TagRow>> {
        return get('tags', id); 
    }
    public function getTagRow_(id:Int, done:Cb<TagRow>):Void {
        getTagRow( id ).then(done.yield()).unless(done.raise());
    }
    public function getTag(id : Int):Promise<Null<Tag>> {
        return getTagRow( id ).transform.fn(_ != null ? Tag.fromRow(_) : null);
    }
    public function getTag_(id:Int, done:Cb<Tag>):Void {
        getTag( id ).then(done.yield()).unless(done.raise());
    }
    public function getTagRowByName(name : String):Promise<Null<TagRow>> {
        return find('tags', function(row : TagRow):Bool {
            return (row.name == name || row.aliases.has( name ));
        });
    }
    public function getTagRowByName_(name:String, done:Cb<TagRow>):Void {
        getTagRowByName( name ).then(done.yield()).unless(done.raise());
    }

    /**
      * create or retrieve a row from [this] table
      */
    public function cogTagRow(name:String, ?type:TagType, done:Cb<TagRow>):Void {
        getTagRowByName_(name, function(?err, ?row) {
            if (err != null)
                done(err);
            else if (row != null)
                done(null, row);
            else {
                add(name, type, function(?err, ?row) {
                    if (err != null)
                        done(err);
                    else
                        done(null, row);
                });
            }
        });
    }

    /**
      * pushes a Tag onto the database, first pushing all of its supers
      */
    public function putTag(tag:Tag, done:Cb<TagRow>):Void {
        var steps:Array<VoidAsync> = new Array();
        if (tag.id == null) {
            steps.push(function(next:VoidCb) {
                getTagRowByName( tag.name ).then(function(row) {
                    if (row != null) {
                        tag.id = row.id;
                        next();
                    }
                    else {
                        putTagRow_(new Tag(tag.name).toRow(), function(?err,?row) {
                            next( err );
                        });
                    }
                }).unless(next.raise());
            });
        }
        if (tag.supers != null) {
            for (dep in tag.supers) {
                steps.push( dep.sync );
                continue;
                steps.push(function(next:VoidCb) {
                    putTag(dep, function(?err, ?row) {
                        next( err );
                    });
                });
            }
        }
        steps.series(function(?error) {
            if (error != null) {
                done( error );
            }
            else {
                putTagRow_(tag.toRow(), done);
            }
        });
    }

    /**
      * 
      */
    public function pullTag(key:EitherType<Int, String>, done:Cb<Tag>):Void {
        var getter : Async<TagRow>;
        if ((key is Int)) {
            getter = getTagRow_.bind(cast(key, Int), _);
        }
        else if ((key is String)) {
            getter = getTagRowByName_.bind(cast(key, String), _);
        }
        else {
            throw 'Error: Invalid key';
        }
        getter(function(?error, ?tagRow) {
            if (error != null) {
                done( error );
            }
            else if (tagRow == null) {
                putTagRow_(new Tag(cast key).toRow(), function(?err, ?tagRow) {
                    if (err != null) return done( err );
                    Tag.loadFromRow(tagRow, dbr, done);
                });
            }
            else {
                Tag.loadFromRow(tagRow, dbr, done);
            }
        });
    }

    // get all tag rows
    public function getAllTagRows():ArrayPromise<TagRow> {
        return Promise.create({
            @forward getAll('tags');
        }).array();
    }
    public function getAllTagRows_(done : Cb<Array<TagRow>>):Void {
        getAllTagRows().then(done.yield()).unless(done.raise());
    }

/* === Instance Fields === */
}

typedef TagRow = {
    ?id: Int,
    name: String,
    aliases: Array<String>,
    ?supers: Array<Int>,
    type: String
};
