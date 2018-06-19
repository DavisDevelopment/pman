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

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.FunctionTools;
using tannus.ds.AnonTools;
using tannus.macro.MacroTools;

//@:genericBuild(pman.ds.ModelBuilder.build())
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
        addSignal('change', new Signal2());
        addSignal('create', new Signal());
        addSignal('delete', new Signal());

        _fields_ = {};
        _props_ = new Map();
    }

    public function get<T>(k: String):Null<T> {
        return
            if (hasAttr( k ))
                getAttr( k );
            else if (hasProp( k ))
                getProp( k );
            else null;
    }

    public function set<T>(k:String, v:T):T {
        if (hasAttr(k))
            return setAttr(k, v);
        else if (hasProp(k))
            return setProp(k, v);
        else
            return setAttr(k, v);
    }

    public function add<T>(name:String, value:T, ?options:ModelPropInitOpts<T>):T {
        if (options != null) {
            deleteAttr( name );
            return _mpv(addProp(name, value, options).value);
        }
        else {
            return set(name, value);
        }
    }

    public inline function exists(k: String):Bool {
        return (hasAttr(k) || hasProp(k));
    }

    @:native('rm')
    public inline function delete(k: String):Bool {
        return (deleteAttr(k)||deleteProp(k));
    }

    public inline function getAttr<T>(k: String):Null<T> {
        return _fields_[k];
    }
    public inline function setAttr<T>(k:String, v:T):T {
        return
            if (hasAttr( k ))
                _fields_[k] = v;
            else initAttr(k, v);
    }
    public inline function hasAttr(k: String):Bool {
        return _fields_.exists( k );
    }
    public inline function deleteAttr(k: String):Bool {
        return _fields_.remove( k );
    }
    public inline function initAttr<T>(k:String, v:T):T {
        deleteProp( k );
        addSignal('change:$k', new Signal2());
        addSignal('delete:$k', new VoidSignal());
        return _fields_[k] = v;
    }
    public inline function iterAttrs():Iterator<String> {
        return _fields_.keys().iterator();
    }

    public function initProp<T>(name:String, value:T, ?options:ModelPropInitOpts<T>):ModelPropNode<T> {
        options = _fillInitOptions(options != null ? options : {});

        addSignal('change:$name', new Signal2());
        addSignal('delete:$name', new VoidSignal());

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

    public function getProp<T>(name: String):Null<T> {
        _expire( name );
        if (hasProp(name))
            return _mpv(_getpv(name));
        else 
            return null;
    }

    public function setProp<T>(name:String, value:T):T {
        _expire( name );
        return _mpv(addProp(name, value, null).value);
    }

    public inline function iterProps():Iterator<String> {
        return _props_.keys();
    }

    public function keyset():Set<String> {
        var keys:Set<String> = new Set();
        keys.pushMany(_fields_.keys());
        for (k in iterProps())
            keys.push( k );
        return keys;
    }

    public function keys():Iterator<String> {
        return keyset().iterator();
    }

    public inline function hasProp(name:String):Bool {
        return (_props_.exists( name ) && _checkExpiry( name ));
    }

    public function deleteProp(name: String):Bool {
        if (hasProp(name)) {
            _props_.remove( name );
            dispatch( 'delete:$name' );
            dispatch('delete', name);
            removeSignal('delete:$name');
            return true;
        }
        else return false;
    }

    @:keep
    private function hxSerialize(s: Serializer) {
        inline function put(x: Dynamic) s.serialize( x );

        var keys:Array<Array<String>> = [
            _fields_.keys(),
            [for (key in iterProps())
                if (!_props_[key].noSave)
                    key 
            ]
        ];

        put(keys[0].length);
        put(keys[1].length);
        
        if (!keys[0].empty()) {
            for (key in keys[0]) {
                put( key );
                put(getAttr( key ));
            }
        }

        if (!keys[1].empty()) {
            for (key in keys[1]) {
                put( key );
                put(_props_[key]);
            }
        }
    }

    @:keep
    private function hxUnserialize(u: Unserializer) {
        inline function get():Dynamic return u.unserialize();

        _init_();
        var len = [(get():Int), (get():Int)];
        
        if (len[0] > 0) {
            for (i in 0...len[0])
                setAttr(get(), get());
        }

        if (len[1] > 0) {
            var key:String;
            for (i in 0...len[1]) {
                key = get();
                addProp(key, null);
                _props_[key] = cast get();
            }
        }
    }

    public function serialize():String {
        Serializer.USE_CACHE = true;
        return Serializer.run( this );
    }

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

    inline function _getpv<T>(k: String):Null<ModelPropValue<T>> {
        return cast _props_[k].value;
    }

    inline function _setpv<T>(k:String, v:ModelPropValue<T>):ModelPropValue<T> {
        return cast _props_[k].value = v;
    }

    inline function _mpv<T>(v: ModelPropValue<T>):T {
        return switch v {
            case null: null;
            case VNormal(x): x;
            default: throw 'TypeError: Invalid ModelPropValue $v';
        };
    }

    inline function _fillInitOptions<T>(o: ModelPropInitOpts<Dynamic>):ModelPropInitOpts<T> {
        if (o.timeout != null) {
            o.expirationDate = Date.fromTime(Date.now().getTime() + (o.timeout * 1000));
            Reflect.deleteField(o, 'timeout');
        }

        o.noSave = (o.noSave == null || o.noSave);

        return o;
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
