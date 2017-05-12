package pman.media.info;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import pman.core.*;
import pman.display.*;
import pman.display.media.*;
import pman.db.*;
import pman.media.*;
import pman.db.MediaStore;
import pman.db.TagsStore;
import pman.media.MediaType;
import pman.async.*;

import haxe.Serializer;
import haxe.Unserializer;

import tannus.ds.SortingTools.*;
import electron.Tools.defer;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;
using tannus.ds.SortingTools;
using pman.async.VoidAsyncs;
using pman.async.Asyncs;

@:expose('TrackTag')
class Tag implements IComparable<Tag> {
    /* Constructor Function */
    public inline function new(name:String, ?id:Int, ?type:TagType, ?aliases:Array<String>):Void {
        this.id = id;
        this.name = name;
        this.type = (type != null ? type : Normal);
        this.aliases = (aliases != null ? aliases : []);
        this.supers = null;
    }

/* === Instance Methods === */

    /**
      * create and return an exact copy of [this] Tag
      */
    public function clone():Tag {
        return new Tag(name, id, type);
    }

    /**
      * convert to a TagRow
      */
    public function toRow():TagRow {
        var row:TagRow = {
            name: name,
            type: Serializer.run( type ),
            aliases: aliases
        };
        if (id != null)
            row.id = id;
        if (supers != null) {
            row.supers = [];
            for (s in supers) {

            }
        }
        return row;
    }

    /**
      * resolve derived tag's 'supers' into two-dimensional Array of dependencies that can be resolved top-down
      */
    public function resolveDependencies():Array<Array<Tag>> {
        var deps:Array<Array<Tag>> = new Array();
        // create, if necessary, and return a 'layer' of the dependency hierarchy
        inline function layer(i : Int):Array<Tag> {
            return deps[i] == null ? deps[i] = [] : deps[i];
        }
        // write an Array of tags onto the specified layer
        inline function mergelayer(i:Int, dl:Array<Tag>)
            deps[i] = layer( i ).concat( dl );

        if (supers == null) {
            return deps;
        }
        else {
            for (st in supers) {
                var dh = st.resolveDependencies();
                for (i in 0...dh.length) {
                    var l = dh[i];
                    if (l != null) {
                        mergelayer(i, l);
                    }
                }
                layer(st.depCount()).push( st );
            }
            return deps;
        }
    }

    /**
      * check how many 'dependencies' this tag has
      */
    public inline function depCount():Int {
        return (supers == null ? 0 : supers.length);
    }

    /**
      * compare [this] Tag to another Tag
      */
    public function compareTo(other : Tag):Int {
        return Reflect.compare(name, other.name);
    }

    /**
      * check whether [this] Tag is described by the given word
      */
    public function is(word : String):Bool {
        var kwl = keywords();
        return kwl.has( word );
    }

    /**
      * obtain all 'keywords' that [this] tag would encompass
      */
    public function keywords():Array<String> {
        var kwl = new Set();
        kwl.push( name );
        kwl.pushMany( aliases );
        if (supers != null) {
            for (dep in supers) {
                kwl.pushMany(dep.keywords());
            }
        }
        return kwl.toArray();
    }

    /**
      * declare that [this] tag inherits from the given tag
      */
    public function inherits(superTag : Tag):Tag {
        if (supers == null) {
            supers = [superTag];
            return this;
        }
        else {
            for (st in supers) {
                if (superTag.name == st.name)
                    return this;
            }
            supers.push( superTag );
            return this;
        }
    }

    /**
      * pull data from the given TagRow
      */
    public function pullRow(row:TagRow, db:PManDatabase, done:VoidCb):Void {
        id = row.id;
        aliases = row.aliases;
        var sups:Array<Tag> = (supers!=null?supers:[]);
        supers = new Array();
        var steps:Array<VoidAsync> = new Array();
        if (row.supers != null) {
            for (depId in row.supers) {
                steps.push(function(next : VoidCb) {
                    var existing = sups.firstMatch.fn(_.id == depId);
                    if (existing == null) {
                        db.tagsStore.pullTag(depId, function(?error, ?depTag) {
                            if (error != null) {
                                next( error );
                            }
                            else {
                                if (depTag == null) {
                                    next('Error: Tag "${name}" references a tag with id=${depId}; no such tag exists');
                                }
                                else {
                                    supers.push( depTag );
                                    next();
                                }
                            }
                        });
                    }
                    else {
                        db.tagsStore.getTagRow_(depId, function(?error, ?depRow) {
                            if (error != null) {
                                next( error );
                            }
                            else {
                                if (depRow == null) {
                                    next('Error: Tag "${name}" references a tag with id=${depId}; no such tag exists');
                                }
                                else {
                                    existing.pullRow(depRow, db, next);
                                }
                            }
                        });
                    }
                });
            }
        }
        steps.series(function(?error) {
            done( error );
        });
    }

    /**
    /**
    /**
    /**
      * 'fill' [this] tag by either
      * (A) doing nothing, if tag already has all its info
      * (B) pull info from db and writing it onto this tag instance
      * (C) add brand new tag row to database
      */
    public function fillOut(done : VoidCb):Void {
        var db = BPlayerMain.instance.db;
        // if [this] tag is not empty
        trace('filling in tag info..');
        // if tag has id field
        if (!isEmpty()) {
            // fetch the row from the db
            getFromDb(function(?err, ?row) {
                if (err != null) {
                    done( err );
                }
                // if no errors occurred fetching the row
                else {
                    // merge the 'aliases' fields
                    trace('merging alias lists..');
                    aliases = aliases.concat( row.aliases ).unique();
                    aliases.sort.fn([x,y]=>Reflect.compare(x,y));
                    trace('merge complete');
                    done();
                }
            });
        }
        // if this tag is empty (only has name)
        else {
            return done('devour the cheeks');
            // attempt to get the row for this tag
            getFromDb(function(?err, ?dbt) {
                if (err != null)
                    done( err );
                // if no row was found
                else if (dbt == null) {
                    // write new row onto database
                    db.tagsStore.putTag(this, function(?err, ?dbtr) {
                        if (err != null) {
                            done( err );
                        }
                        else {
                            // once written, pull data from the row onto this
                            pullRow(dbtr, db, done);
                        }
                    });
                }
                // if row was found
                else {
                    // pull row data onto this
                    pullFrom( dbt );
                    done();
                }
            });
        }
    }

/* === Instance Fields === */

    public var name: String;
    public var id: Null<Int>;
    public var aliases: Array<String>;
    public var supers: Null<Array<Tag>> = null;
    public var type: TagType;

/* === Static Methods === */

    /**
      * build a Tag instance from a Tag row
      */
    public static function fromRow(row : TagRow):Tag {
        var tag = new Tag(row.name, row.id, Unserializer.run(row.type), row.aliases);
        return tag;
    }

    /**
      * utilizing the database where necessary, build a Tag instance from a Tag row
      */
    public static function loadFromRow(row:TagRow, db:PManDatabase, done:Cb<Tag>):Void {
        var tag = fromRow( row );
        var steps:Array<VoidAsync> = new Array();
        if (row.supers != null) {
            for (depId in row.supers) {
                steps.push(function(next : VoidCb) {
                    db.tagsStore.getTagRow_(depId, function(?error, ?depRow) {
                        if (error != null) {
                            next( error );
                        }
                        else {
                            if (depRow == null) {
                                next('Error: Tag "${tag.name}" references a tag with id=${depId}; no such tag exists');
                            }
                            else {
                                loadFromRow(depRow, db, function(?error, ?depTag:Tag) {
                                    if (error != null) {
                                        next( error );
                                    }
                                    else {
                                        tag.supers.push( depTag );
                                        next();
                                    }
                                });
                            }
                        }
                    });
                });
            }
        }
        steps.series(function(?error) {
            done(error, tag);
        });
    }
}

enum TagType {
    Normal;
}
