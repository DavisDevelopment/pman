package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.http.Url;
import tannus.async.*;
import tannus.nore.ORegEx;

import pman.core.*;
import pman.display.*;
import pman.display.media.*;
import pman.edb.*;
import pman.edb.MediaStore;
import pman.media.MediaType;
import pman.async.*;
import pman.async.tasks.TrackBatchCache;

import pman.media.info.*;
import pman.bg.media.Mark;
import pman.bg.media.Tag;
import pman.bg.media.MediaRow;
import pman.bg.media.MediaDataSource;
import pman.bg.media.MediaDataDelta;
import pman.async.tasks.TrackDataPullRaw;

import haxe.Serializer;
import haxe.Unserializer;
import haxe.extern.EitherType as Either;
import Type.ValueType;

import edis.Globals.*;
import pman.Globals.*;
import pman.GlobalMacros.*;

import Slambda.fn;
import tannus.node.Buffer;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.async.Asyncs;
using pman.async.VoidAsyncs;
using pman.bg.DictTools;
using tannus.FunctionTools;
using tannus.html.JSTools;
using pman.media.MediaTools;
using pman.media.TrackDataDeltaTools;
using pman.media.TrackDataTools;

class TrackData2 {
    /* Constructor Function */
    public function new(track:Track, ?src:MediaDataSource):Void {
        this.track = track;

        if (src == null) {
            src = Empty;
        }

        sourceChange = new Signal();
        rs = new OnceSignal();
        source = src;
        dsource = Complete;

        __bind();

        if (this.source.match(Create(_))) {
            _defaults();
        }
    }

/* === Instance Methods === */

    /**
      * initialize [this] TrackData
      */
    public function initialize(db:PManDatabase, done:VoidCb):Void {
        done();
    }

    /**
      * check if [this] is ready
      */
    public function isReady():Bool {
        return rs.isReady();
    }

    /**
      * await readiness
      */
    public function onReady(f: Void->Void):Void {
        return rs.on( f );
    }

    /**
      * give [this] its source
      */
    public function pullSource(row:MediaRow, src:MediaDataSourceDecl, done:VoidCb, ?db:PManDatabase, ?cache:DataCache):Void {
        dsource = src;

        _loadSource(row,
            (switch ( src ) {
                case Partial(names): names;
                case Complete: _all_;
                case Empty: [];
            }),
            db, cache
        )
        .then(function(src: MediaDataSource) {
            _rebase( src );

            done();
        }, done.raise());
    }

    /**
      * 'rebase' [this] TrackData 
      */
    public function _rebase(src: MediaDataSource):Void {
        this.source = src;
        this.dsource = (switch ( src ) {
            case Empty: Empty;
            case Complete(_): Complete;
            case Create(_): Complete;
            case Partial(names, _): Partial( names );
        });
    }

    /**
      * resample [this]'s properties to the full property list
      */
    public function fill(?done: VoidCb):Void {
        switch ( source ) {
            case Complete(_), Create(_):
                if (done != null) {
                    done();
                }

            default:
                resample(_all_.copy(), done);
        }
    }

    /**
      * reassign [this]'s property list
      */
    public function resample(properties:Array<String>, ?done:VoidCb):Void {
        if (done == null) {
            done = VoidCb.noop;
        }

        var newProps = organizePropertyList(properties);
        var curProps = organizePropertyList(getPropertyNames());

        var rm = [], mk = [];
        for (n in _all_) {
            // current source has [n] property, but [newProps] does not
            if (curProps.has( n ) && !newProps.has( n )) {
                rm.push( n );
            }
            else if (newProps.has( n ) && !curProps.has( n )) {
                mk.push( n );
            }
        }

        /**
          debug info
         **/
        /*
        echo({
            all: _all_.copy(),
            push: mk.copy(),
            pop: rm.copy()
        });
        */

        unset( rm );
        expand(mk, done);
    }

    /**
      * expand [this]'s properties to include [props]
      */
    public function expand(props:Array<String>, done:VoidCb):Void {
        // skip if [props] is empty
        if (props.empty()) {
            return done();
        }

        // ensure that [props] contains only the names of properties that ARE NOT currently mounted
        var nm = organizePropertyList(props.without(getPropertyNames()));
        //trace('[attempt #1]', nm);
        var nm2 = props.toSet().without(getPropertyNames().toSet()).toArray().propList();
        //trace('[attempt #2]', nm2);

        switch ( source ) {
            case Create(d), Complete(d), Partial(_, d):
                if (d.row != null) {
                    _loadSource(d.row, nm2)
                        .unless(done.raise())
                        .then(function(ps: MediaDataSource) {
                            _rebase(source.extend( ps ));

                            defer(done.void());
                        });
                }
                else done('No row to work with');

            case Empty:
                throw 'Error: Cannot "expand" from an Empty TrackData; must perform standard load first';
        }
    }

    /**
      * reduce [this]'s properties to the given list
      */
    public function curtail(props: Array<String>):TrackData {
        // transform [props] into the list of fields to delete
        var cpl = getPropertyNames();
        props = cpl.without(props.intersection( cpl ));

        // delete them
        unset( props );

        return this;
    }

    /**
      * remove all fields in [props] from [this] data
      */
    public function unset(props: Array<String>):Void {
        if (isEmpty()) return ;
        // get only the items in [props] that refer to actual properties of [this]
        props = organizePropertyList( props ).filter.fn(hasOwnProperty(_));
        var myProps:Array<String> = getPropertyNames( source );
        myProps = organizePropertyList(myProps.without( props ));
        if (myProps.empty()) {
            return _rebase(Empty);
        }

        switch ( source ) {
            case Complete( data ), Create( data ):
                data = data.cloneState();
                data.initial.deleteFields( props );
                data.current.deleteFields( props );
                return _rebase(Partial(myProps, data));

            case Partial(a, data):
                data = data.cloneState();
                data.initial.deleteFields( props );
                data.current.deleteFields( props );
                for (x in props) {
                    a.remove( x );
                }
                return _rebase(Partial(myProps, data));

            case Empty:
                //... wut?
                throw 'Error: Cannot perform "unset" on Empty';
        }
    }

    /**
      * retrieve source data
      */
    private function _loadSource(row:MediaRow, properties:Array<String>, ?db:PManDatabase, ?cache:DataCache):Promise<MediaDataSource> {
        return Promise.create({
            var task = new TrackDataPullRaw(this, {
                db: db,
                cache: cache,
                row: row,
                properties: properties.copy()
            });
            return cast task.pull();
        });
    }

    /**
      * convert [this] TrackData to a MediaRow
      */
    public function toRaw():Null<MediaRow> {
        var raw:Null<MediaRow> = null;
        switch ( source ) {
            // empty data
            case Empty:
                throw 'Error: Cannot export empty TrackData to MediaRow';
                //return null;

            // complete data
            case Complete( data ), Create( data ), Partial(_, data):
                raw = _buildMediaRow(_dataRow());
        }
        return echo( raw );
    }

    /**
      * build out a MediaDataRow from the NullableMediaDataState given
      */
    private function _dataRowFromState(o: NullableMediaDataState):MediaDataRow {
        var row:MediaDataRow = {
            views: 0,
            starred: false,
            marks: [],
            tags: [],
            actors: [],
            meta: null
        };

        nullSet(row.views, o.views);
        nullSet(row.starred, o.starred);
        nullSet(row.channel, o.channel);
        nullSet(row.rating, o.rating);
        nullSet(row.contentRating, o.contentRating);
        nullSet(row.description, o.description);
        
        if (o.marks != null) {
            row.marks = o.marks.map.fn(_.toJson());
        }

        if (o.tags != null) {
            row.tags = o.tags.map.fn(_.name);
        }

        if (o.actors != null) {
            row.actors = o.actors.map.fn(_.name);
        }

        if (o.attrs != null) {
            row.attrs = o.attrs.toAnon();
        }

        if (o.meta != null) {
            row.meta = o.meta.toRaw();
        }

        return row;
    }

    /**
      * data row
      */
    private function _dataRow():MediaDataRow {
        var o:Dynamic = getSourceData( source );
        if (o != null)
            o = o.row;
        if (o != null)
            o = o.data;
        if (o == null)
            o = {};
        var d:Null<MediaDataRow> = o;
        var row:MediaDataRow = {
            views: nullOr(views, d.views),
            starred: nullOr(starred, d.starred),
            channel: nullOr(channel, d.channel),
            rating: nullOr(rating, d.rating),
            contentRating: nullOr(contentRating, d.contentRating),
            description: nullOr(description, d.description),
            marks: [],
            tags: [],
            actors: [],
            attrs: null,
            meta: null
        };

        if (meta != null) {
            row.meta = meta.toRaw();
        }

        if (attrs != null) {
            row.attrs = attrs.toAnon();
        }

        if (marks != null) {
            row.marks = marks.map.fn(_.toJson());
        }

        if (tags != null)
            row.tags = tags.map.fn(_.name);

        if (actors != null)
            row.actors = actors.map.fn(_.name);

        return row;
    }

    /**
      * build out a MediaRow from the given MediaDataRow
      */
    private inline function _buildMediaRow(dataRow: MediaDataRow):MediaRow {
        return {
            _id: media_id,
            uri: track.uri,
            data: dataRow
        };
    }

    /**
      * encode an attribute value
      */
    private function _encodeAttrVal(value: Dynamic):Dynamic {
        //TODO actually encode values
        return value;
    }

    /**
      * save [this] data in the database
      */
    public function save(?complete:VoidCb, ?db:PManDatabase):Void {
        // compute appropriate 'write' function 
        var writef:PManDatabase->VoidCb->Void = (switch ( source ) {
            // if the data is complete, just save all of it (for now)
            case Complete(_), Create(_):
                _writeall;

            // if data is partial, save the changes that have been made to the data we have
            case Partial(_, _): 
                _writedmg;

            // bitch about attempts to save null data
            case Empty:
                throw 'Cannot save empty TrackData to database';
        });

        _sync_(writef, complete, db);
    }

    /**
      * push [this] TrackData to the database
      */
    public function _sync_(write:PManDatabase->VoidCb->Void, ?complete:VoidCb, ?db:PManDatabase):Void {
        // ensure that [complete] isn't null
        if (complete == null)
            complete = VoidCb.noop;

        // ensure that [db] isn't null
        if (db == null)
            db = PManDatabase.get();

        // create a list of steps
        var steps:Array<VoidAsync> = [
            _prepush.bind(db, _),
            write.bind(db, _)
        ];

        steps.series( complete );
    }

    /**
      * save [this] by writing to the database all of the changes that have been made locally since the last write
      */
    private function _writedmg(db:PManDatabase, done:VoidCb):Void {
        var dmg = getDataRowDelta();

        echo('-- data row delta --');
        echo( dmg );

        if (dmg != null) {
            db.media.applyDelta(media_id, dmg, function(?error, ?row:MediaRow) {
                if (error != null) {
                    done( error );
                }
                else {
                    pullSource(row, dsource, done.wrap(function(_done, ?error) {
                        _done( error );
                    }));
                }
            });
        }
        else done();
    }

    /**
      * save [this] by writing the data as a whole onto the database
      */
    private function _writeall(db:PManDatabase, done:VoidCb):Void {
        var newRow:MediaRow = toRaw();
        if (newRow != null) {
            db.media.putRow(newRow, function(?error, ?row:MediaRow) {
                if (error != null) {
                    done( error );
                }
                else {
                    echo( row );
                    pullSource(row, dsource, done);
                }
            });
        }
        else {
            done();
        }
    }

    /**
      * save tags and actors to the database
      */
    private function _prepush(db:PManDatabase, done:VoidCb):Void {
        if (checkPropsAny(['actors', 'tags'])) {
            var steps:Array<VoidAsync> = new Array();

            // push [tags]
            if (checkProperty('tags')) {
                steps.push(function(next: VoidCb) {
                    var tagNames:Array<String> = tags.map.fn( _.name );
                    db.tags.cogRows( tagNames ).then(function(x) next(), next.raise());
                });
            }

            // push [actors]
            if (checkProperty('actors')) {
                steps.push(function(next) {
                    db.actors.cogRowsFromNames(actors.map.fn(_.name)).then(x->next(), next.raise());
                });
            }

            steps.series( done );
        }
        else {
            done();
        }
    }

    /**
      * ensure that [this] is usable
      */
    private function assertUsable(?prop: Either<String, Array<String>>):Void {
        if (isEmpty()) {
            //throw 'Error: Cannot read or modify "empty" TrackData';
            throw TrackDataError.ErrInvalidAccess();
        }
        else if (prop != null) {
            var names:Array<String> = [];
            if ((prop is String)) {
                names = [prop];
            }
            else {
                names = cast prop;
            }

            for (name in names) {
                if (!checkProperty( name )) {
                    throw TrackDataError.ErrInvalidAccess( name );
                }
            }
        }
    }
    private inline function au(?prop: Either<String, Array<String>>):Void {
        assertUsable( prop );
    }

    /**
      * sort [marks]
      */
    public function sortMarks():Void {
        au( 'marks' );
        marks.sort((x, y) -> Reflect.compare(x.time, y.time));
    }

    /**
      * add a new Mark to [this]
      */
    public function addMark(mark : Mark):Void {
        au( 'marks' );
        switch ( mark.type ) {
            case Begin, End, LastTime:
                //marks = marks.filter.fn(!_.type.equals( mark.type ));
                removeMarksOfType( mark.type );
                marks.push( mark );

            case Scene(type, name):
                removeMarksOfType( mark.type );
                marks.push( mark );

            case Named( name ):
                marks.push( mark );
        }
        sortMarks();
    }

    /**
      * remove all marks of the given type
      */
    public function removeMarksOfType(mt : MarkType):Void {
        au('marks');
        filterMarks.fn(!_.type.equals( mt ));
    }
    public function removeBeginMark():Void removeMarksOfType( Begin );
    public function removeEndMark():Void removeMarksOfType( End );
    public function removeLastTimeMark():Void removeMarksOfType( LastTime );

    /**
      * remove a specific Mark
      */
    public function removeMark(mark : Mark):Void {
        filterMarks.fn(_ != mark);
    }

    /**
      * filter [marks]
      */
    public function filterMarks(f : Mark->Bool):Void {
        au('marks');
        marks = marks.filter( f );
    }

    public function getMarkq(f : Mark->Bool):Null<Mark> {
        au('marks');
        return marks.firstMatch( f );
    }
    public function getMarkByType(type : MarkType):Null<Mark> {
        return getMarkq.fn(_.type.equals( type ));
    }

    /**
      * get [this] Track's last time
      */
    public function getLastTime():Null<Float> {
        return _getTime( LastTime );
    }

    /**
      * get [this] Track's begin time
      */
    public function getBeginTime():Null<Float> {
        return _getTime( Begin );
    }

    /**
      * get [this] Track's end time
      */
    public inline function getEndTime():Null<Float> {
        return _getTime( End );
    }

    /**
      * set the time for the Mark of the given type
      */
    private function _setTime(type:MarkType, time:Float):Void {
        removeMarksOfType( type );
        addMark(new Mark(type, time));
    }

    /**
      * get the time for a Mark of the given type
      */
    private function _getTime(type:MarkType):Null<Float> {
        var m:Null<Mark> = getMarkByType( type );
        return (m != null ? m.time : null);
    }

    /**
      * set [this] Track's last time
      */
    public inline function setLastTime(time : Float):Void {
        _setTime(LastTime, time);
    }

    /**
      * set [this] Track's begin time
      */
    public inline function setBeginTime(time : Float):Void {
        _setTime(Begin, time);
    }

    /**
      * set [this] Track's end time
      */
    public inline function setEndTime(time : Float):Void {
        _setTime(End, time);
    }

    /**
      * attach a Tag instance to [this]
      */
    public function attachTag(tag : Tag):Tag {
        au('tags');
        for (t in tags) {
            if (t.name == tag.name) {
                return t;
            }
        }
        tags.push( tag );
        return tag;
    }

    /**
      * detach a Tag from [this]
      */
    public function removeTag(tag: EitherType<String, Tag>):Bool {
        au( 'tags' );
        for (t in tags) {
            if ((tag is String) && t.name == tag) {
                tags.remove( t );
                return true;
            }
            else if ((tag is Tag) && (tag : Tag).equals( t )) {
                tags.remove( t );
                return true;
            }
        }
        return false;
    }

    /**
      * attach a Tag to [this] as a String
      */
    public function addTag(tagName : String):Tag {
        return attachTag(new Tag({
            name: tagName
        }));
    }

    /**
      * select tag by oregex
      */
    public function selectTag(pattern : String):Null<Tag> {
        au('tags');
        var reg:RegEx = new RegEx(new EReg(pattern, 'i'));
        return tags.firstMatch.fn(reg.match( _.name ));
    }

    /**
      * checks for attached tag by given name
      */
    public function hasTag(name: String):Bool {
        au('tags');
        for (t in tags)
            if (t.name == name)
                return true;
        return false;
    }

    /**
      * attach an Actor object to [this]
      */
    public function attachActor(actor : Actor):Void {
        au('actors');
        if (!hasActor( actor.name )) {
            actors.push( actor );
        }
    }

    /**
      * add an Actor to [this] by name
      */
    public function addActor(name : String):Void {
        attachActor(new Actor({
            name: name
        }));
    }

    /**
      * check whether the given Actor is attached to [this]
      */
    public function hasActor(name : String):Bool {
        au('actors');
        for (actor in actors) {
            if (actor.name == name) {
                return true;
            }
        }
        return false;
    }

    /**
      * select a single Actor by predicate function
      */
    public function selectActor(predicate : Actor -> Bool):Maybe<Actor> {
        au('actors');
        return actors.firstMatch( predicate );
    }

    /**
      * select a single Actor by ORegEx
      */
    public function oreselectActor(ore : String):Maybe<Actor> {
        return selectActor(untyped ORegEx.compile( ore ));
    }

    /**
      * detach an Actor from [this]
      */
    public function detachActor(actor : Actor):Void {
        au('actors');
        var todel = [];
        for (a in actors) {
            if (a.equals( actor )) {
                todel.push( a );
            }
        }
        for (a in todel) {
            actors.remove( a );
        }
    }

    /**
      * remove an Actor from [this]
      */
    public function removeActor(name : String):Void {
        au('actors');
        //var actor = oreselectActor('[name="$name"]');
        var actor = selectActor(fn(_.name == name));
        if (actor == null) {
            return ;
        }
        else {
            detachActor( actor );
        }
    }

    /**
      * get the value of [attrs]'s [attribute] field
      */
    public function getAttr<T>(attribute:String, ?default_val:T):Null<T> {
        au();
        if (hasOwnProperty('attrs')) {
            if (attrs == null) {
                return null;
            }
            else {
                return nullOr(attrs[attribute], default_val);
            }
        }
        else {
            throw ErrInvalidAccess('attrs');
        }
    }

    /**
      * set the value of an attribute [attrs]
      */
    public function setAttr<T>(attribute:String, value:T):T {
        au();
        if (hasOwnProperty('attrs')) {
            if (attrs == null) {
                attrs = new Dict();
            }
            return attrs.set(attribute, value);
        }
        else {
            throw ErrInvalidAccess('attrs');
        }
    }

    /**
      * check for existence of an attribute of the given name
      */
    public function hasAttr(attribute: String):Bool {
        au();
        if (hasOwnProperty('attrs')) {
            if (attrs != null)
                return attrs.exists( attribute );
            else return false;
        }
        else throw ErrInvalidAccess('attrs');
    }

    /**
      * delete an attribute
      */
    public function removeAttr(attribute: String):Bool {
        au();
        if (hasOwnProperty('attrs')) {
            return (attrs != null ? attrs.remove(attribute) : false);
        }
        else throw ErrInvalidAccess('attrs');
    }

    /**
      * getter/setter method for attributes
      */
    public function attr(a:Dynamic, ?b:Dynamic):Dynamic {
        if ((a is String)) {
            return
            if (b != null)
                setAttr(cast a, b);
            else
                getAttr(cast a);
        }
        else if (Reflect.isObject( a )) {
            for (n in Reflect.fields( a )) {
                setAttr(n, Reflect.field(a, n));
            }
        }
        return null;
    }

    /**
      * push an Actor onto [this]
      */
    public function pushActor(name:String, done:Cb<Actor>):Void {
        database.actorStore.cogActor(name, function(?error, ?actor) {
            if (error != null) {
                done(error, null);
            }
            else if (actor != null) {
                attachActor( actor );
                done(null, actor);
            }
        });
    }

    /**
      * push several Actors onto [this]
      */
    public function pushActors(names:Array<String>, done:Cb<Array<Actor>>):Void {
        database.actorStore.cogActorsFromNames(names, function(?error, ?al) {
            if (error != null) {
                return done(error, null);
            }
            else if (al != null) {
                for (a in al) {
                    attachActor( a );
                }
                done(null, al);
            }
        });
    }

    /**
      * set [this]'s 'actors' field
      */
    public function writeActors(names:Array<String>, done:Cb<Array<Actor>>):Void {
        var prevActors = actors.copy();
        actors = new Array();
        pushActors(names, done);
    }

    /**
      * load the MediaRow for [this]
      */
    private function fetch_row(?done: Cb<MediaRow>):Promise<MediaRow> {
        return ((function() {
            if (media_id != null) {
                return {
                    x:media_id,
                    f:database.media.getRowById
                };
            }
            else if (track.uri.hasContent()) {
                return {
                    x:track.uri,
                    f:database.media.cogRow
                };
            }
            else return null;
        }())
        .passTo(o -> o.f(o.x, done)));
    }

    /**
      * edit [this] TrackData object
      */
    public function edit(action:TrackData->VoidCb->Void, done:VoidCb, _save:Bool=true):Void {
        var steps:Array<VoidAsync> = [action.bind(this, _)];
        if ( _save ) {
            steps.push(untyped save.bind(_, null));
        }
        steps.series( done );
    }

/* === Utility Methods === */

    /**
      * check whether [this] TrackData is empty
      */
    public function isEmpty():Bool {
        return source.match(Empty);
    }
    public inline function hasContent():Bool return !isEmpty();

    /**
      * check for existence of a property
      */
    public function hasOwnProperty(prop: String):Bool {
        switch ( source ) {
            case Empty:
                return false;

            case Complete(_), Create(_):
                return _all_.has( prop );

            case Partial(names, _):
                return names.has( prop );
        }
    }

    /**
      * check for existence of a set of properties
      */
    public function hasOwnPropertySet(props:Array<String>, all:Bool=true):Bool {
        return (all ? props.all : props.any)(prop -> hasOwnProperty( prop ));
    }

    /**
      * check the given property
      */
    public function checkProperty(property:String, ?dv:Dynamic):Bool {
        // check that property is even declared to exist
        if (hasOwnProperty( property )) {
            // get the value of the property
            var value:Dynamic = getProp( property );
            if (value != null) {
                return true;
            }
            else if (dv != null) {
                setProp(property, dv);
                return checkProperty( property );
            }
            else {
                return false;
            }
        }
        else {
            return false;
        }
    }

    /**
      * check the given list of properties
      */
    public function checkProps(props:Array<String>, all:Bool=true):Bool {
        if (props.empty() || isEmpty()) {
            return false;
        }

        return (all ? props.all : props.any)(prop -> checkProperty( prop ));
    }
    public inline function checkPropsAny(props: Array<String>):Bool return checkProps(props, false);

    /**
      * get the property-list from the given [src]
      */
    public function getPropertyNames(?src: MediaDataSource):Array<String> {
        if (src == null) {
            src = source;
        }

        switch ( src ) {
            case Partial(names, _):
                return names;

            case Complete(_), Create(_):
                return _all_;

            case Empty:
                return [];
        }
    }

    /**
      * get the underlying object from the given [src]
      */
    public function getSourceData(?src: MediaDataSource):Null<MediaDataSourceState> {
        if (src == null) {
            src = source;
        }

        switch ( src ) {
            case Partial(_, data), Complete(data), Create(data):
                return data;

            case Empty:
                return null;
        }
    }

    /**
      * get the object-state of [this] TrackData
      */
    public function getDataState(?src: MediaDataSource):Null<NullableMediaDataState> {
        if (src == null) {
            src = source;
        }

        switch ( src ) {
            case Empty:
                return null;

            case Complete(data), Create(data), Partial(_, data):
                return data.current;
        }
    }

    /**
      * get the 
      */
    public function getSelfDelta():Null<MediaDataDelta> {
        return trackDataDelta();
    }

    /**
      * get the delta for the database entry itself
      */
    public function getDataRowDelta():Null<MediaDataRowDelta> {
        var mdd:Null<MediaDataDelta> = getSelfDelta();
        //trace( mdd );
        if (mdd == null) {
            return null;
        }
        else {
            var mdrd = mdd.toRowDelta();
            //trace( mdrd );
            return mdrd;
        }
    }

    /**
      * property binding
      */
    private function __bind():Void {
        for (property in _all_) {
            defineProperty(property, {
                get: getProp.bind(property),
                set: setProp.bind(property, _)
            });
        }
    }

    /**
      * assign default property values
      */
    private function _defaults():Void {
        views = 0;
        starred = false;
        channel = null;
        rating = null;
        contentRating = null;
        description = null;

        attrs = null;
        meta = null;
        marks = new Array();
        tags = new Array();
        actors = new Array();
    }

    /**
      * fill in null-properties with default values
      */
    private function _fillDefaults():Void {
        inline function dv(n:String, v:Dynamic) {
            if (hasOwnProperty( n ) && getProp( n ) == null) {
                setProp(n, v);
            }
        }

        dv('views', 0);
        dv('starred', false);
        dv('channel', null);
        dv('rating', null);
        dv('contentRating', 'NR');
        dv('description', null);

        dv('attrs', null);
        dv('meta', null);
        dv('marks', new Array());
        dv('tags', new Array());
        dv('actors', new Array());
    }

    private function _default(prop: String):Null<Dynamic> {
        var values:Map<String, Dynamic> = [
            'views' => 0,
            'starred' => false,
            'contentRating' => 'NR',
            'tags' => [],
            'marks' => [],
            'actors' => []
        ];
        return values[prop];
    }

    /**
      * get a property value
      */
    private function getPropertyValue<T>(property:String, source:MediaDataSource):Null<T> {
        switch ( source ) {
            // partial data
            case Partial(names, data):
                // if [property] is a field of [this] partial data
                if (names.has( property )) {
                    //return fieldGet(data.current, property);
                    //return data.current.fieldGet( property );
                    return either(data.current.fieldGet(property), _default(property));
                }
                else {
                    return null;
                }

            // complete data
            case Complete( data ), Create( data ):
                return either(data.current.fieldGet(property), _default(property));
                //return data.current.fieldGet( property );

            // no data
            case Empty:
                return null;
        }
    }

    /**
      * get a property value
      */
    private function getProp<T>(name: String):Null<T> {
        if (source == null)
            throw 'No [source]';
        return getPropertyValue(name, source);
    }

    /**
      * set a property value
      */
    private function setPropertyValue<T>(property:String, value:Null<T>, source:MediaDataSource):Null<T> {
        switch ( source ) {
            // no data
            case Empty:
                return null;

            // complete data
            case Complete( data ), Create( data ):
                return data.current.fieldSet(property, value);

            // partial data
            case Partial(names, data):
                if (names.has( property )) {
                    return data.current.fieldSet(property, value);
                }
                else {
                    return null;
                }
        }
    }

    /**
      * set a property value
      */
    private function setProp<T>(name:String, value:Null<T>):Null<T> {
        if (source == null)
            throw 'No [source]';
        return setPropertyValue(name, value, this.source);
    }

    private static inline function either<T>(x:Null<T>, y:Null<T>):Null<T> {
        return 
            if (x != null) x;
            else y;
    }
    private static function any<T>(opts: Array<Null<T>>):Null<T> {
        return either(opts.shift(), {
            if (opts.length > 1)
                any( opts );
            else
                opts[0];
        });
    }

/* === Static Methods === */

    /**
      * get the MediaDataSourceDecl for the given property-list
      */
    @:native('a')
    public static function getMediaDataSourceDeclFromPropertyList(properties: Array<String>):MediaDataSourceDecl {
        properties = organizePropertyList( properties );

        if (properties.empty()) {
            return MediaDataSourceDecl.Empty;
        }
        else if (properties.length == _all_.length) {
            for (i in 0..._all_.length) {
                if (properties[i] != _all_[i]) {
                    return MediaDataSourceDecl.Partial( properties );
                }
            }
            return MediaDataSourceDecl.Complete;
        }
        else {
            return MediaDataSourceDecl.Partial( properties );
        }
    }

    /**
      * get the MediaDataSource for the given MediaDataSourceDecl value
      */
    @:native('b')
    public static function createMediaDataSource(decl:MediaDataSourceDecl, ?data:MediaDataSourceState):MediaDataSource {
        switch ( decl ) {
            // empty data
            case Empty:
                if (data != null) {
                    throw 'Error: Declared empty, but data provided';
                }

                return MediaDataSource.Empty;

            // complete data
            case Complete:
                if (data == null) {
                    throw 'Error: No data provided';
                }

                return Complete( data );

            case Partial(properties):
                if (data == null) {
                    throw 'Error: No data provided';
                }

                return Partial(organizePropertyList(properties), data);
        }
    }

    /**
      * properly organize a property-list
      */
    @:native('c')
    private static function organizePropertyList(names: Array<String>):Array<String> return names.propList();

/* === Instance Methods === */

    /**
      * the [source] property
      */
    public var source(default, set): MediaDataSource;
    private function set_source(newSource: MediaDataSource) {
        var delta:Delta<MediaDataSource> = new Delta(newSource, source);
        var res = (source = newSource);
        sourceChange.call( delta );
        if (!rs.isReady()) {
            switch ([delta.previous, delta.current]) {
                //case {previous: null|Empty, current:current} if (current != null && current != Empty):
                case [null|Empty, current] if (current != null && current != Empty):
                    rs.announce();

                case [Partial(_,_)|Create(_)|Complete(_), Empty]:
                    throw 'Aww, dat not right, sha';

                default:
                    null;
            }
        }
        return res;
    }

/* === Instance Fields === */

    // the Track object to which [this] is attached
    public var track: Track;

    // the 'id' for [this]'s media object
    public var media_id : Null<String>;

    public var views : Int;
    public var starred : Bool;
    public var rating : Null<Float>;
    public var description : Null<String>;
    public var attrs : Dict<String, Dynamic>;
    public var marks : Array<Mark>;
    public var tags: Array<Tag>;
    public var actors : Array<Actor>;
    public var channel : Null<String>;
    public var contentRating : Null<String>;
    public var meta : Null<MediaMetadata>;

    // the MediaDataSourceDecl value
    public var dsource(default, null): MediaDataSourceDecl;

    // event for when the value of [source] changes
    private var sourceChange: Signal<Delta<MediaDataSource>>;

    // event for when [this] is ready
    private var rs: OnceSignal;

/* === Static Fields === */

    // list of all property names for [this]
    //public static var _all_:Array<String> = {[
        //'views', 'starred', 'rating', 'description',
        //'attrs', 'marks', 'tags', 'actors', 'channel',
        //'contentRating', 'meta'
    //];};
    public static var _all_:Array<String> = {[
        "actors",
        "attrs",
        "channel",
        "contentRating",
        "description",
        "marks",
        "meta",
        "rating",
        "starred",
        "tags",
        "views"
    ];};

    // list of all properties that are stored in the database "as-is" (meaning that they're not stored in separate tables)
    public static var _inline_:Array<String> = {[
        'attrs',
        'channel',
        'contentRating',
        'description',
        'marks',
        'meta',
        'rating',
        'starred',
        'views'
    ];};

    // list of all mapped property's names
    public static var _mapped_:Array<String> = {[
        'attrs', 'marks', 'tags', 'actors', 'meta'
    ];};
}

typedef DataCache = {
    actors: Dict<String, Actor>,
    tags: Dict<String, Tag>
};

// TrackData-specific errors
enum TrackDataError {
    ErrInvalidAccess(?property: String);
}
