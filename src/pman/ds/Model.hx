package pman.ds;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;
import tannus.TSys as Sys;

import pman.events.EventEmitter;
import pman.GlobalMacros.*;

import haxe.Serializer;
import haxe.Unserializer;

import edis.Globals.*;
import pman.Globals.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.ds.IteratorTools;
using tannus.FunctionTools;
using tannus.ds.AnonTools;
using tannus.async.Asyncs;

using tannus.macro.MacroTools;

@:expose
class Model extends EventEmitter {
    /* Constructor Function */
    public function new() {
        super();

        _init_();
    }

/* === Instance Methods === */

    /**
      initialize fields upon construction
     **/
    function _init_() {
        _sigs = new Map();
        __checkEvents = true;

        addSignal('change', new Signal2());
        addSignal('create', new Signal());
        addSignal('delete', new Signal2());

        _fields_ = {};
        _props_ = new Map();
    }

    /**
      clear all attributes, properties, and event-signals from [this] Model
     **/
    public function clear() {
        for (key in keys()) {
            delete( key );
        }

        for (evt in _sigs.keys()) {
            removeSignal( evt );
        }
        
        _init_();
    }

    /**
      get a field of [this] Model
      NOTE
      uses JavaScript-specific syntactic magic to be faster and more concise
     **/
    public inline function get<T>(k: String):Null<T> {
        return cast 
            (untyped __js__(
                '{0} || {1}', 
                getAttr(k),
                getProp(k)
            ));
    }

    /**
      set the value of a field of [this] Model
     **/
    public inline function set<T>(key:String, value:T):T {
        return (hasProp(key) ? setProp(key, value) : setAttr(key, value));
    }

    /**
      initialize and/or assign value to the given field
     **/
    public function add<T>(name:String, value:T, ?options:ModelPropInitOpts<T>):T {
        if (options != null) {
            deleteAttr( name );
            return _mpv(addProp(name, value, options).value);
        }
        else {
            return set(name, value);
        }
    }

    /**
      check for the existence of some field named [k]
     **/
    public inline function exists(k: String):Bool {
        return (hasAttr(k) || hasProp(k));
    }

    /**
      delete field [k] from [this]
     **/
    @:native('rm')
    public inline function delete(k: String):Bool {
        return (deleteAttr(k)||deleteProp(k));
    }

    /**
      magical wrapper method for handling the bullshit surrounding 'set' operations
     **/
    inline function _changeAttr<T>(key:String, f:Void->T):T {
        var prev = getAttr(key), ret, delta;
        //try {
            ret = f();
            delta = new Delta(getAttr(key), prev);
            scheduleDispatch('change:$key', delta.previous, delta.current);
            scheduleDispatch('change', key, delta);
        //}
        //catch (err: Dynamic) {
            //TODO?
        //}
        return ret;
    }

    /**
      magical wrapper method for handling the bullshit surrounding 'set' operations
     **/
    inline function _changeProp<T>(key:String, f:Void->T):T {
        var prev = getProp(key), delta, ret;
        ret = f();
        delta = new Delta(getProp(key), prev);
        scheduleDispatch('change:$key', delta.previous, delta.current);
        scheduleDispatch('change', key, delta);
        return ret;
    }

    /**
      initialize the events associated with [k] and announce the initialization of the field
     **/
    inline function _init(k:String, v:Dynamic, announce:Bool=true) {
        initFieldEvents( k );
        if ( announce ) {
            scheduleDispatch('create', k)
                .then(function() {
                    dispatch('change', k, new Delta(v, null));
                    dispatch('change:$k', null, v);
                }, report);
        }
    }

    /**
      get the value of an attribute of [this]
     **/
    public inline function getAttr<T>(k: String):Null<T> {
        return _fields_[k];
    }

    /**
      reassign the value of an attribute of [this]
     **/
    public function setAttr<T>(name:String, value:T):T {
        return _changeAttr(
            name,
            () -> (hasAttr( name ) ? _fields_[name] = value : initAttr(name, value))
        );
    }

    public inline function hasAttr(k: String):Bool {
        return _fields_.exists( k );
    }

    /**
      delete the registry for the given attribute
     **/
    public inline function deleteAttr(k: String):Bool {
        var rem = _fields_.remove( k );
        deleteFieldEvents( k );
        return rem;
    }

    public function initAttr<T>(k:String, v:T):T {
        deleteProp( k );
        _init(k, v);
        return _fields_[k] = v;
    }

    public inline function iterAttrs():Iterator<String> {
        return _fields_.keys().iterator();
    }

    public function initProp<T>(name:String, value:T, ?options:ModelPropInitOpts<T>):ModelPropNode<T> {
        options = _fillInitOptions(options != null ? options : {});

        _init(name, value);

        _props_.set(name, {
            value: VNormal(value),
            expirationDate: options.expirationDate,
            noSave: options.noSave
        });
        return _mpv(_props_[name].value);
    }

    public function addProp<T>(name:String, value:T, ?o:ModelPropInitOpts<T>):ModelPropNode<T> {
        if (!hasProp( name )) {
            return initProp(name, value, o);
        }
        else {
            if (_mpv(_getpv(name)) != value) {
                _setpv(name, VNormal(value));
            }
            return cast _props_[name];
        }
    }

    /**
      modify the configuration of a property stored in [_props_]
     **/
    public function modProp<T>(name:String, options:ModelPropInitOpts<T>) {
        if (hasProp( name )) {
            var node = _props_[name];
            
            if (options.timeout != null && (options.timeout < 0 || !options.timeout.isFinite())) {
                Reflect.deleteField(node, 'expirationDate');
                Reflect.deleteField(options, 'timeout');
            }

            options = _fillInitOptions( options );
            
            if (options.expirationDate != null) {
                node.expirationDate = options.expirationDate;
            }

            if (options.noSave != null) {
                node.noSave = options.noSave;
            }
        }
    }

    /**
      obtain the value of a property of [this] Model
     **/
    public function getProp<T>(name: String):Null<T> {
        _expire( name );
        if (hasProp(name))
            return _mpv(_getpv(name));
        else 
            return null;
    }

    /**
      assign the value of a property of [this] Model
     **/
    public function setProp<T>(name:String, value:T):T {
        _expire( name );
        return _mpv(addProp(name, value, null).value);
    }

    /**
      iterate over names of properties of [this] Model
     **/
    public inline function iterProps():Iterator<String> {
        return _props_.keys();
    }

    /**
      obtain a Set<String> containing keys for all attributes and properties of [this] Model
     **/
    public function keyset():Set<String> {
        var keys:Set<String> = new Set();
        keys.pushMany(_fields_.keys());
        for (k in iterProps())
            keys.push( k );
        return keys;
    }

    /**
      Iterator<String> for of [keyset]
     **/
    public function keys():Iterator<String> {
        return keyset().iterator();
    }

    /**
      check whether [this] Model has a property stored under the given key
     **/
    public inline function hasProp(name:String):Bool {
        return (_props_.exists( name ) && _checkExpiry( name ));
    }

    /**
      delete the property indicated by [name]
     **/
    public function deleteProp(name: String):Bool {
        if (hasProp(name)) {
            _props_.remove( name );
            deleteFieldEvents( name );
            return true;
        }
        else return false;
    }

    /**
      initialize field-related event-signals
     **/
    inline function initFieldEvents(name: String) {
        addSignal('change:$name', new Signal2());
        addSignal('delete:$name', new VoidSignal());
    }

    /**
      delete and deallocate the event-signals for the given field
     **/
    function deleteFieldEvents(name: String) {
        dispatch('delete:$name');
        dispatch('delete', name);
        removeSignal('delete:$name');
    }

    /**
      serializer method for [this] Model class
     **/
    @:keep
    private function hxSerialize(s: Serializer) {
        inline function put(x: Dynamic) s.serialize( x );

        /* create manifest of all fields to be serialized */
        var keys:Array<Array<String>> = [
            //_fields_.keys(),
            //[for (key in iterProps())
                //if (!_props_[key].noSave)
                    //key 
            
            //]
            for (x in keyset_pair())
                x.toArray()
        ];

        // filter keys to ensure that none that won't get serialized are included in the count;
        keys[1] = keys[1].map.fn(new Pair(_, _props_[_])).filter.fn(_.right == null || _.right.noSave || isExpired(_.right)).map.fn(_.left);
        keys[1].sort(untyped Reflect.compare);

        // serialize the number of keys for each field-type respectively
        put(keys[0].length);
        put(keys[1].length);
        
        // serialize attributes
        if (!keys[0].empty()) {
            for (key in keys[0]) {
                // key, value
                put( key );
                put(_fields_[key]);
            }
        }

        // serialize properties
        if (!keys[1].empty()) {
            var node: ModelPropNode<Dynamic>;
            for (key in keys[1]) {
                // check whether 
                node = _props_[key];
                if (node.noSave || isExpired(node))
                    continue;

                // key, property-node (ModelPropNode)
                put( key );
                hxSerializePropertyNode(s, node);
            }
        }

        // serialize [this]'s typename
        try {
            put(Type.getClassName(Type.getClass( this )));
        }
        catch (err: Dynamic) {
            put(Type.getClassName(Model));
        }

        // serialize whether there are additional values
        put( false );
    }

    /**
      serialize a ModelPropNode object
     **/
    @:keep
    function hxSerializePropertyNode(s:Serializer, node:ModelPropNode<Dynamic>) {
        inline function put(x: Dynamic) s.serialize( x );
        /*
        var nv:ModelPropValue = node.value, nva = nv.getParameters();
        put(nv.getName());
        put( nva.length );
        for (x in nva) {
            put( x );
        }
        */

        // do it, sha
        put( node.value );

        // should I serialize the order in which the properties are saved..?
        put( node.expirationDate );
    }

    /**
      unserializer method for [this] Model class
     **/
    @:keep
    private function hxUnserialize(u: Unserializer) {
        // shorthand function for unserializing values
        inline function get():Dynamic return u.unserialize();

        throw 'Error: hxUnserialize should not even get invoked';
        // call [_init_] (which acts, basically, as the constructor)
        _init_();

        // deserialize the numbers of keys in each field-group respectively
        var len = [(get():Int), (get():Int)];
        
        // deserialize attributes
        if (len[0] > 0) {
            for (i in 0...len[0])
                setAttr(get(), get());
        }

        // deserialize properties
        if (len[1] > 0) {
            var key:String;
            for (i in 0...len[1]) {
                key = get();
                addProp(key, null);
                _props_[key] = cast get();
            }
        }
    }

    /**
      serialize [this] Model instance into a String
     **/
    public function serialize():String {
        var s:Serializer = new Serializer();
        s.useCache = true;
        //s.serialize( this );
        hxSerialize( s );
        return s.toString();
    }

    /**
      create and return a snapshot of [this]'s data-state
     **/
    public function getData(?data_keys:Set<String>, clone:Bool=false):ModelDataState {
        var kp = keyset_pair(data_keys);
        var state:ModelDataState = {
            f: new Anon(),
            p: new Anon()
        };
        //state.f.assign(_fields_);
        for (key in kp[0])
            state.f[key] = _fields_[key];
        for (key in kp[1]) {
            var node = _props_[key];
            if (clone)
                node = node.deepCopy(true);
            state.p[key] = node;
        }
        
        return state;
    }

    /**
      write the given state onto [this] Model, as-is
     **/
    public function putData(state: ModelDataState) {
        for (key in state.f.keys()) {
            initAttr(key, state.f[key]);
        }

        var node;
        for (key in state.p.keys()) {
            node = state.p[key];
            if (node == null)
                continue;
            else if (isExpired(node))
                continue;

            addProp(key, _mpv(node.value), {
                expirationDate: node.expirationDate,
                noSave: node.noSave
            });
        }
    }

    /**
      restore [this] Model to the given state
     **/
    public function restoreData(state: ModelDataState) {
        clear();
        echo( this );
        putData( state );
    }

    /**
      split the given key-set into a pair of keylists, one for attributes and the other for properties
     **/
    function keyset_pair(?keys: Set<String>):Array<Set<String>> {
        if (keys == null) {
            return [
                _sset(_fields_.keys()),
                _sset(_props_.keys().array())
            ];
        }
        else {
            var pair = [new Set<String>(), new Set<String>()];
            for (key in keys) {
                if (hasProp(key)) {
                    pair[1].push( key );
                }
                else {
                    // if it's not a property, then it's assumed to be a reference to an attribute that may or may not yet exist
                    pair[0].push( key );
                }
            }
            return pair;
        }
    }

    /**
      remove expired properties
     **/
    inline function _expire(name: String) {
        if (!_checkExpiry(name)) {
            deleteProp( name );
        }
    }

    /**
      check whether [name] is 'expired'
     **/
    inline function _checkExpiry(name: String):Bool {
        return !(
            _props_.exists( name ) && 
            _props_[name].expirationDate != null &&
            (_props_[name].expirationDate.getTime() <= Date.now().getTime())
        );
    }

    static inline function isExpired<T>(node: ModelPropNode<T>):Bool {
        return (node.expirationDate == null ? false : isMoreRecent(Date.now(), node.expirationDate));
    }

    static inline function isMoreRecent(l:Date, r:Date):Bool return (compareDates(l, r) >= 0);
    static inline function isLessRecent(l:Date, r:Date):Bool return (compareDates(l, r) < 0);
    static inline function compareDates(l:Date, r:Date):Int { return Reflect.compare(l.getTime(), r.getTime()); }

    /**
      obtain reference to the ModelPropValue for the given property
     **/
    inline function _getpv<T>(k: String):Null<ModelPropValue<T>> {
        return cast _props_[k].value;
    }

    /**
      assign the ModelPropValue to the given property
     **/
    inline function _setpv<T>(k:String, v:ModelPropValue<T>):ModelPropValue<T> {
        return cast _props_[k].value = v;
    }

    /**
      extract concrete value from the given ModelPropValue
     **/
    inline static function _mpv<T>(v: ModelPropValue<T>):T {
        return switch v {
            case null: null;
            case VNormal(x): x;
            default: throw 'TypeError: Invalid ModelPropValue $v';
        };
    }

    static function _sset(i: Iterable<String>):Set<String> {
        var res = new Set();
        res.pushMany( i );
        return res;
    }

    /**
      fill out/correct the given ModelPropInitOpts object
     **/
    inline static function _fillInitOptions<T>(o: ModelPropInitOpts<Dynamic>):ModelPropInitOpts<T> {
        if (o.timeout != null) {
            o.expirationDate = Date.fromTime(Date.now().getTime() + (o.timeout * 1000));
            Reflect.deleteField(o, 'timeout');
        }

        o.noSave = (o.noSave == null || o.noSave);

        return o;
    }

    /**
      deserialize a new Model instance from the given String
     **/
    public static function deserializeStringToModel<T:Model>(s: String):Null<T> {
        var state:ModelDataState = deserializeString( s );
        var model:Model = Type.createEmptyInstance(Type.resolveClass( state.t ));
        model._init_();
        model.putData( state );
        return cast model;
    }

    public static function deserializeToModel<T:Model>(u: Unserializer):Null<T> {
        var state:ModelDataState = deserialize( u );
        var model = Type.createEmptyInstance(Type.resolveClass( state.t ));
        model._init_();
        model.putData( state );
        return cast model;
    }

    /**
      do dat serializin' stuff raut der' meh sha
      (decode a ModelDataState object from [s])
     **/
    @:keep
    public static function deserialize(u: Unserializer):ModelDataState {
        inline function val():Dynamic return u.unserialize();

        var lens:Array<Int> = [val(), val()];
        var anons:Array<Anon<Any>> = [
            new Anon(),
            new Anon()
        ];

        switch lens {
            case [null|0, null|0]:
                null;

            // valid numbers that require computations
            case [nattrs, nprops]:
                for (i in 0...nattrs)
                    anons[0].set((val():String), val());

                for (i in 0...nprops)
                    anons[1].set((val():String), (val() : ModelPropNode<Any>));

            case _:
                null;
        }

        var type_name:String = val();

        return {
            f: anons[0],
            p: cast anons[1],
            t: type_name
        };
    }

    @:keep
    public static function deserializeString(s: String):ModelDataState {
        var u = new Unserializer( s );
        return deserialize( u );
    }

/* === Computed Instance Fields === */
/* === Instance Fields === */

    var _fields_: Anon<Dynamic>;
    var _props_: Map<String, ModelPropNode<Dynamic>>;
}

@:structInit
class ModelPropNode<T> {
    public var value: ModelPropValue<T>;
    //@:optional
    public var expirationDate: Null<Date>;
    //@:optional
    public var noSave: Bool;
}

typedef ModelPropInitOpts<T> = {
    ?expirationDate: Date,
    ?timeout: Float,
    ?noSave: Bool
};

enum ModelPropValue<T> {
    VNormal(v: T) :ModelPropValue<T>;
}

typedef ModelDataState = {
    var f: Anon<Dynamic>;
    var p: Anon<ModelPropNode<Dynamic>>;
    @:optional var t: String;
};
