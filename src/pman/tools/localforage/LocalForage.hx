package pman.tools.localforage;

import tannus.ds.*;
import tannus.node.*;
import tannus.async.*;

import js.Promise as Prom;

class LocalForage {
    private static var i : LocalForageExternInstance = {untyped LocalForageExtern;};
    public static function getItem<T>(key:String, ?done:Cb<Maybe<T>>):Null<Promise<Maybe<T>>> {
        return prom(i.getItem(key, done));
    }
    public static function setItem<T>(key:String, value:T, ?done:Cb<Maybe<T>>):Null<Promise<Maybe<T>>> {
        return prom(i.setItem(key, value, done));
    }
    public static function removeItem(key:String, ?done:VoidCb):Null<Promise<Dynamic>> return prom(i.removeItem(key, done));
    public static function clear(done : VoidCb):Void return i.clear( done );
    public static function length(?done : Cb<Int>):Null<Promise<Int>> return prom(i.length(done));
    public static function key(index:Int, ?done:Cb<String>):Null<Promise<String>> return prom(i.key(index, done));
    public static function keys(?done : Cb<Array<String>>):Null<Promise<Array<String>>> return prom(i.keys(done));
    public static function iterate(iterCallback:Dynamic->String->Int->Void, ?done:VoidCb):Null<Promise<Dynamic>> return prom(i.iterate(iterCallback, done));
    public static function setDriver(driver : String):Void return i.setDriver( driver );
    public static function config(options : Dynamic):Void return i.config( options );
    public static function defineDriver(driverDefinition : DriverDefinition):Void return i.defineDriver( driverDefinition );
    public static function driver():String return i.driver();
    public function ready(callback : VoidCb):Void {
        i.ready().then(untyped callback, untyped callback);
    }
    public static function createInstance(?options : Dynamic):LocalForageInstance {
        return new LocalForageInstance(i.createInstance( options ));
    }

    private static inline function prom<T>(x:Null<Prom<T>>):Maybe<Promise<T>> {
        if (x == null) {
            return null;
        }
        else {
            return Promise.fromJsPromise( x );
        }
    }
}



class LocalForageInstance {
    private var i : LocalForageExternInstance;
    public function new(i : LocalForageExternInstance) {
        this.i = i;
    }

    public function getItem<T>(key:String, ?done:Cb<Maybe<T>>):Null<Promise<Maybe<T>>> {
        return prom(i.getItem(key, done));
    }
    public function setItem<T>(key:String, value:T, ?done:Cb<Maybe<T>>):Null<Promise<Maybe<T>>> {
        return prom(i.setItem(key, value, done));
    }
    public function removeItem(key:String, ?done:VoidCb):Null<Promise<Dynamic>> return prom(i.removeItem(key, done));
    public function clear(done : VoidCb):Void return i.clear( done );
    public function length(?done : Cb<Int>):Null<Promise<Int>> return prom(i.length(done));
    public function key(index:Int, ?done:Cb<String>):Null<Promise<String>> return prom(i.key(index, done));
    public function keys(?done : Cb<Array<String>>):Null<Promise<Array<String>>> return prom(i.keys(done));
    public function iterate(iterCallback:Dynamic->String->Int->Void, ?done:VoidCb):Null<Promise<Dynamic>> return prom(i.iterate(iterCallback, done));
    public function setDriver(driver : String):Void return i.setDriver( driver );
    public function config(options : Dynamic):Void return i.config( options );
    public function defineDriver(driverDefinition : DriverDefinition):Void return i.defineDriver( driverDefinition );
    public function driver():String return i.driver();
    public function ready(callback : VoidCb):Void {
        i.ready().then(untyped callback, untyped callback);
    }
    public function createInstance(?options : Dynamic):LocalForageInstance {
        return new LocalForageInstance(i.createInstance( options ));
    }

    private inline function prom<T>(x:Null<Prom<T>>):Maybe<Promise<T>> {
        if (x == null) {
            return null;
        }
        else {
            return Promise.fromJsPromise( x );
        }
    }
}

@:jsRequire( 'localforage' )
extern class LocalForageExtern {
    public static function getItem<T>(key:String, ?done:Cb<Maybe<T>>):Null<Prom<Maybe<T>>>;
    public static function setItem<T>(key:String, value:T, ?done:Cb<Maybe<T>>):Null<Prom<Maybe<T>>>;
    public static function removeItem(key:String, ?done:VoidCb):Null<Prom<Dynamic>>;
    public static function clear(done : VoidCb):Void;
    public static function length(?done : Cb<Int>):Null<Prom<Int>>;
    public static function key(index:Int, ?done:Cb<String>):Null<Prom<String>>;
    public static function keys(?done : Cb<Array<String>>):Null<Prom<Array<String>>>;
    public static function iterate(iterCallback:Dynamic->String->Int->Void, ?done:VoidCb):Null<Prom<Dynamic>>;
    public static function setDriver(driver : String):Void;
    public static function config(options : Dynamic):Void;
    public static function defineDriver(driverDefinition : DriverDefinition):Void;
    public static function driver():String;
    public static function ready():Prom<Dynamic>;
    public static function createInstance(?options : Dynamic):LocalForageExternInstance;
}

extern class LocalForageExternInstance {
    public function getItem<T>(key:String, ?done:Cb<Maybe<T>>):Null<Prom<Maybe<T>>>;
    public function setItem<T>(key:String, value:T, ?done:Cb<Maybe<T>>):Null<Prom<Maybe<T>>>;
    public function removeItem(key:String, ?done:VoidCb):Null<Prom<Dynamic>>;
    public function clear(done : VoidCb):Void;
    public function length(?done : Cb<Int>):Null<Prom<Int>>;
    public function key(index:Int, ?done:Cb<String>):Null<Prom<String>>;
    public function keys(?done : Cb<Array<String>>):Null<Prom<Array<String>>>;
    public function iterate(iterCallback:Dynamic->String->Int->Void, ?done:VoidCb):Null<Prom<Dynamic>>;
    public function setDriver(driver : String):Void;
    public function config(options : Dynamic):Void;
    public function defineDriver(driverDefinition : DriverDefinition):Void;
    public function driver():String;
    public function ready():Prom<Dynamic>;
    public function createInstance(?options : Dynamic):LocalForageExternInstance;
}

typedef DriverDefinition = {
    _driver: String,
    _initStorage: Dynamic->Void,
    clear: VoidCb->Void,
    getItem: String->Cb<Dynamic>->Void,
    setItem: String->Dynamic->Cb<Dynamic>->Void,
    removeItem: String->VoidCb->Void,
    key: Int->Cb<String>->Void,
    keys: Cb<Array<String>>->Void,
    length: Cb<Int>->Void
};
