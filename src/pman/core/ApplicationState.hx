package pman.core;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;
import tannus.async.promises.*;
import tannus.TSys as Sys;

import edis.libs.localforage.LocalForage;
import edis.storage.kv.*;
import edis.storage.fs.async.*;

import pman.events.EventEmitter;
import pman.ds.OnceSignal;
import pman.ds.*;
import pman.ds.Model;
import pman.ds.io.*;
import pman.ds.io.FileModelPersistor;

import haxe.Serializer;
import haxe.Unserializer;
import haxe.rtti.Meta;

import edis.Globals.*;
import pman.Globals.*;
import pman.GlobalMacros.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.FunctionTools;
using tannus.ds.MapTools;
using tannus.ds.DictTools;
using tannus.ds.AnonTools;
using tannus.async.Asyncs;

/**
  models and manages overarching application-wide state configuration
 **/
@:expose
class ApplicationState {
    /* Constructor Function */
    public function new():Void {
        _init_();
    }

/* === Instance Methods === */

    /**
      initialize [this] object
     **/
    function _init_():Void {
        ports = new Map();
        models = new Map();

        fs = engine.fileSystem;
        area = new LocalForageStorageArea(LocalForage.instance);
        _rs = new OnceSignal();

        /**
          add a Model to [this]'s registry
         **/
        inline function addModel(model: Model) {
            var name = _key(model);
            this.addModel(name, model);
            this.addModel(name, model);
            ports[name] = new EdisStoragePort(area, name);
        }

        lock();
        addModel(player = new PlayerConfig());
        addModel(sessMan = new SessManConfig());
        addModel(playback = new PlaybackConfig());
        addModel(rendering = new RenderingConfig());
        addModel(misc = new MiscData());
        unlock();

        var all_path:Path = (Paths.userData().plusString('/appstate.dat'));
        all_port = new FilePort(fs, all_path);
        ports[':all:'] = all_port.map((b -> b.toString()), (s -> ByteArray.ofString(s)));
    }

    /**
      deallocate the memory associated with [this] object
     **/
    function _dispose_():Void {
        inline function rm(name: String) {
            Reflect.deleteField(this, name);
        }

        rm('models');
        rm('player');
        rm('playback');
        rm('rendering');
        rm('sessMan');
        rm('misc');
        rm('fs');
        rm('ports');
    }

    /**
      initialize [this] object's asynchronous resources
     **/
    public function initialize(done: VoidCb):Void {
        //done = done.nn().wrap(function(_, ?error) {
            //_rs.announce();
            //_(error);
        //});

        vsequence(
            function(add, exec) {
                // initialize [this]'s storageArea
                add( area.initialize );

                // initialize [this]'s storage-ports
                for (key in ports.keys()) {
                    add(cb -> ports[key].initialize( cb ));
                }

                var raw = porti(':all:');
                var cooked: String = '';
                raw.then(d -> (cooked = d));

                // load [this] from memory
                add(load.bind(null, null).toAsync());

                // execute the sequence we've built
                exec();
            },
            function(?error) {
                if (error != null) {
                    done( error );
                }
                else {
                    done();
                    _rs.announce();
                }
            }
        );
    }

    /**
      initialize a given Model
     **/
    inline function _init_model_(m: Model):Void {
        m.on('change', function(property, x, y) {
            if (isReady() && !isIOLocked())
                save(m, IO_Update);
        });
    }

    /**
      handle the serialization of [this] object
     **/
    @:keep
    @:access(pman.ds.Model)
    function hxSerialize(s: Serializer):Void {
        inline function put(x: Dynamic) s.serialize( x );

        player.hxSerialize( s );
        playback.hxSerialize( s );
        sessMan.hxSerialize( s );
        rendering.hxSerialize( s );
        misc.hxSerialize( s );
    }

    /**
      handle the deserialization of [this] object
     **/
    @:keep
    function hxUnserialize(u: Unserializer):Void {
        inline function val():Dynamic return u.unserialize();

        lock();
        var state: ModelDataState = null;
        if (player == null) {
            player = Model.deserializeToModel( u );
        }
        else {
            player.putData(state = Model.deserialize( u ));
        }

        if (playback == null) {
            playback = Model.deserializeToModel( u );
        }
        else {
            playback.putData(state = Model.deserialize( u ));
        }

        if (sessMan == null) {
            sessMan = Model.deserializeToModel( u );
        }
        else {
            sessMan.putData(state = Model.deserialize( u ));
        }

        if (rendering == null) {
            rendering = Model.deserializeToModel( u );
        }
        else {
            rendering.putData(state = Model.deserialize( u ));
        }

        var ms = misc.getData();
        try {
            if (misc == null)
                misc = Model.deserializeToModel( u );
            else
                misc.putData(state = Model.deserialize( u ));
        }
        catch (error: Dynamic) {
            misc.putData( ms );
        }
        unlock();
    }

    /**
      serialize [this] object into a String
     **/
    public function serialize():String {
        var s = new Serializer();
        s.useCache = true;
        hxSerialize( s );
        return s.toString();
    }

    /**
      unserialize the given [data] String onto [this] object
     **/
    public function unserialize(data: String):Void {
        if (data.empty())
            return ;

        var u = new Unserializer( data );
        hxUnserialize( u );
        return ;
    }

    /**
      get an Array of all Models stored under [this]
     **/
    public function getModels():Map<String, Model> {
        return models.copy();
    }

    public function clearModels():Void {
        for (name in models.keys()) {
            models.remove( name );
        }
    }

    public inline function isReady():Bool {
        return _rs.v;
    }
    public inline function onReady(f: Void->Void) {
        _rs.await( f );
    }

    /**
      persist [this] ApplicationState
     **/
    public function save(?model:Model, ?reason:AppStateIOReason):VoidPromise {
        if (isReady() && !isIOLocked()) {
            //echo('saving ApplicationState..');
            return write(model, reason).unless( report );
        }
        else {
            throw 'Invalid call to ApplicationState.save';
        }
    }

    /**
      restore [this] ApplicationState
     **/
    public function load(?model:Model, ?reason:AppStateIOReason):VoidPromise {
        if (reason == null) {
            reason = IO_Update;
        }
        
        if (!isIOLocked()) {
            if (model != null) {
                return read_model.bind(model, _).toPromise();
            }
            else {
                switch reason {
                    case IO_Update, IO_Finalize, IO_Initialize:
                        return read_all.toPromise();
                }
            }
        }
        else {
            throw 'Invalid call to ApplicationState.load';
        }
    }

    /**
      save [this] state
     **/
    public function write(?model:Model, ?reason:AppStateIOReason):VoidPromise {
        if (reason == null) {
            reason = IO_Update;
        }
        if (model != null) {
            return update_write_model.bind(model, _).toPromise();
        }
        else {
            switch reason {
                case IO_Update:
                    return write_update.toPromise();

                case IO_Finalize|IO_Initialize:
                    return write_all.toPromise();
            } 
        }
    }

    function write_update(done: VoidCb) {
        [
        for (model in getModels())
            update_write_model.bind(model, _)
        ]
        .series(done.wrap(function(_, ?error) {
            _( error );
        }));
    }

    /**
      save the given Model's data
     **/
    inline function update_write_model(model:Model, done:VoidCb) {
        try {
            ports[_key(model)].write(model.serialize(), done);
        }
        catch (error: Dynamic) {
            done( error );
        }
    }

    /**
      save [this] object's data
     **/
    inline function write_all(done: VoidCb):Void {
        try {
            ports[':all:'].write(serialize(), done);
        }
        catch (error: Dynamic) {
            done( error );
        }
    }

    /**
      read the serialized data for [mode]
     **/
    inline function read_model(model:Model, done:VoidCb) {
        try {
            var dp = ports[_key(model)].read();
            dp.then(function(data: String) {
                if (data.empty()) {
                    done();
                }
                else {
                    var state = Model.deserializeString( data );
                    model.putData( state );
                    done();
                }
            }, done.raise());
        }
        catch (error: Dynamic) {
            done( error );
        }
    }

    /**
      read the serialized data for [this] entire object, and unserialize it onto [this] object
     **/
    inline function read_all(done: VoidCb):Void {
        try {
            ports[':all:'].read().then(function(data: String) {
                unserialize( data );
                done();
            }, done.raise());
        }
        catch (error: Dynamic) {
            done( error );
        }
    }

    function porti(k:String, ?dv:String):StringPromise {
        var res:StringPromise = 
            try ports[k].read(null).string() 
            catch (err: Dynamic) Promise.raise(err).string();
        if (dv != null) {
            var dvp = Promise.resolve(dv);
            res = Promise.either(res, dvp).string();
        }
        return res;
    }

    function porto(k:String, d:String):VoidPromise {
        var res = 
            try ports[k].write(d, null)
            catch (err: Dynamic) VoidPromise.raise( err );
        return res;
    }

    inline function addModel(name:String, model:Model) {
        models[name] = model;
        _init_model_( model );
    }

    public inline function isIOLocked():Bool {
        return io_locked;
    }
    public function lock(?type: AppStateLockType) {
        if (type == null)
            type = LtIO;
        switch type {
            case LtIO:
                io_locked = true;
        }
    }
    public function unlock(?type: AppStateLockType) {
        if (type == null)
            type = LtIO;
        switch type {
            case LtIO:
                io_locked = false;
        }
    }

    /**
      get the metadata for the given type
     **/
    static inline function _meta<T:Model>(c: Class<T>):Anon<Array<Dynamic>> {
        return Meta.getType( c );
    }
    static inline function _mkey(c: Class<Model>):String {
        return (_meta(c)['saveName'].join(''));
    }
    static inline function _key(m: Model):String {
        return _mkey(Type.getClass( m ));
    }

/* === Instance Fields === */

    public var player:PlayerConfig;
    public var sessMan:SessManConfig;
    public var playback:PlaybackConfig;
    public var rendering:RenderingConfig;
    public var misc:MiscData;

    var models: Map<String, Model>;
    var ports: Map<String, Port<String>>;

    var fs: FileSystem;
    var area: StorageArea;
    var all_port: Port<ByteArray>;

    var io_locked: Bool = false;

    var _rs: OnceSignal;
}

enum AppStateLockType {
    LtIO;
}

enum AppStateIOReason {
    IO_Update;
    IO_Finalize;
    IO_Initialize;
}

typedef ApplicationStateJsonData = Anon<AppStateJsonProperty>;
typedef AppStateJsonProperty = {
    var value: Null<String>;
};

@saveName('player')
class PlayerConfig extends ProxyModel<PlayerConfigType> {

}

@saveName('sessMan')
class SessManConfig extends ProxyModel<SessManConfigType> {

}

@saveName('playback')
class PlaybackConfig extends ProxyModel<PlaybackConfigType> {

}

@saveName('rendering')
class RenderingConfig extends ProxyModel<RenderingConfigType> {

}

@saveName('misc')
class MiscData extends ProxyModel<MiscDataType> {

}

/**
  underlying type for player-state
 **/
private class PlayerConfigType {
    /* -- general player-related state options -- */
    var showSnapshot:Bool = true;
    var showAlbumArt:Bool = true;
    var mediaTypeSpecificConfig:Bool = false;

    var mediaConfig:PlayerMediaConfig = {{
        visualizer: 'spectograph'
    };};
    var audioConfig:PlayerAudioConfig = {{
        visualizer: 'spectograph'
    };};
    var videoConfig:PlayerVideoConfig = {{
        visualizer: 'spectograph',
        showVisualizer: false,
        audioOnly: false
    };};
}

typedef PlayerMediaConfig = {
    @:defaultTo('spectograph')
    var visualizer:String;
}

typedef PlayerAudioConfig = {
    >PlayerMediaConfig,
    //
}

typedef PlayerVideoConfig = {
    >PlayerMediaConfig,

    var audioOnly:Bool;
    var showVisualizer:Bool;
}

/**
  underlying type for session management configuration
 **/
private class SessManConfigType {
    var restorePreviousSession:Bool = true;
    var autoRestoreSession:Bool = false;
    var autoSaveSession:Bool = true;
    var saveEmptySession:Bool = false;
    var sessionToRestore:String = 'session.dat';
    var sessionSaveName:String = 'session.dat';
}

private class SessionDataType {
    var sessionWasRestored:Bool = false;
}

/**
  underlying type for playback configuration
 **/
private class PlaybackConfigType {
    /* -- misc config options -- */
    var autoPlay:Bool = true;

    /* -- playback options -- */
    var volume:Float = 1.0;
    var speed:Float = 1.0;
    var shuffle:Bool = false;
    var repeat:Int = 0;
    var muted:Bool = false;
}

/**
  underlying type for rendering/display configuration
 **/
private class RenderingConfigType {
    var directRender:Bool = true;
}

private class MiscDataType {
    var lastDirectory: Null<Path> = {new Path('betty');};
    var recentDocuments: Array<Path> = {new Array();};
}
