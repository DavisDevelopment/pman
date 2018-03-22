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
        switch ( source ) {
            // empty data
            case Empty:
                throw 'Error: Cannot export empty TrackData to MediaRow';
                return null;

            // complete data
            case Complete( data ), Create( data ), Partial(_, data):
                return _buildMediaRow(_dataRow());
        }
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

        trace( row );

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
      * push [this] TrackData to the database
      */
    public function save(?complete:VoidCb, ?db:PManDatabase):Void {
        // ensure that [complete] isn't null
        if (complete == null)
            complete = VoidCb.noop;

        // ensure that [db] isn't null
        if (db == null)
            db = PManDatabase.get();

        // create a list of steps
        var steps:Array<VoidAsync> = [
            _prepush.bind(db, _),
            _writeall.bind(db, _)
        ];

        steps.series( complete );
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
        au('tags');
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
        var actor = oreselectActor('[name="$name"]');
        if (actor == null) {
            return ;
        }
        else {
            detachActor( actor );
        }
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
      * check the given property
      */
    public function checkProperty(property:String, ?checks:Array<pman.tools.ValueCheck>):Bool {
        // check that property is even declared to exist
        if (hasOwnProperty( property )) {
            // get the value of the property
            var value:Dynamic = getProp( property );
            if (value != null) {
                return true;
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
    public function checkProps(props: Array<String>):Bool {
        if (props.empty() || isEmpty()) {
            return false;
        }

        for (property in props) {
            if (!checkProperty( property )) {
                return false;
            }
        }
        return true;
    }

    /**
      * get the property-list from the given [src]
      */
    public function getPropertyNames(src: MediaDataSource):Array<String> {
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
    private function getSourceData(src: MediaDataSource):Null<MediaDataSourceState> {
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
      * get a property value
      */
    private function getPropertyValue<T>(property:String, source:MediaDataSource):Null<T> {
        switch ( source ) {
            // partial data
            case Partial(names, data):
                // if [property] is a field of [this] partial data
                if (names.has( property )) {
                    return fieldGet(data.current, property);
                }
                else {
                    return null;
                }

            // complete data
            case Complete( data ), Create( data ):
                return fieldGet(data.current, property);

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
                return fieldSet(data.current, property, value);

            // partial data
            case Partial(names, data):
                if (names.has( property )) {
                    return fieldSet(data.current, property, value);
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

    /**
      * get a property of an object
      */
    private static inline function fieldGet<O,T>(o:O, prop:String):Null<T> {
        return Reflect.field(o, prop);
    }

    /**
      * set a property of an object
      */
    private static inline function fieldSet<O,T>(o:O, prop:String, value:T):T {
        Reflect.setField(o, prop, value);
        return fieldGet(o, prop);
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
    private static function organizePropertyList(names: Array<String>):Array<String> {
        var result = names.filter(name -> name.hasContent());
        result.sort(untyped Reflect.compare);
        return result;
    }

/* === Instance Methods === */

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
                    trace('READY');

                case [Partial(_,_)|Create(_)|Complete(_), Empty]:
                    trace('TrackData has been emptied');
                    throw 'Aww, dat not right, sha';

                default:
                    null;
            }
        }
        return res;
    }

/* === Instance Fields === */

    public var track: Track;

    public var media_id : Null<String>;
    public var views : Int;
    public var starred : Bool;
    public var rating : Null<Float>;
    public var description : Null<String>;
    public var attrs : Dict<String, Dynamic>;
    public var marks : Array<Mark>;
    //public var tags : Array<String>;
    public var tags: Array<Tag>;
    public var actors : Array<Actor>;
    public var channel : Null<String>;
    public var contentRating : Null<String>;
    public var meta : Null<MediaMetadata>;

    public var dsource(default, null): MediaDataSourceDecl;

    private var sourceChange: Signal<Delta<MediaDataSource>>;
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
        'starred'
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
private enum TrackDataError {
    ErrInvalidAccess(?property: String);
}
