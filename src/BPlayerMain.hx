package ;

import tannus.io.*;
import tannus.ds.*;
import tannus.math.Random;
import tannus.graphics.Color;
import tannus.node.ChildProcess;
import tannus.sys.*;
import tannus.internal.CompileTime in Ct;
import tannus.TSys as Sys;

import crayon.*;

import electron.ext.*;
import electron.ext.Dialog;
import electron.ext.MenuItem;
import electron.main.WebContents;
import electron.renderer.IpcRenderer;

import pman.LaunchInfo;
import pman.core.*;
import pman.ui.*;
import pman.db.*;
import pman.edb.*;
import pman.events.*;
import pman.media.*;
import pman.ipc.RendererIpcCommands;
import pman.async.*;

import Std.*;
import edis.Globals.*;
import pman.Globals.*;
import pman.GlobalMacros.*;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;
using pman.media.MediaTools;
using pman.bg.URITools;
using tannus.async.Asyncs;
using tannus.FunctionTools;

class BPlayerMain extends Application {
	/* Constructor Function */
	public function new():Void {
		super();

        engine = new Engine();

		_ready = false;
		_rs = new VoidSignal();
		_rs.once(function() {
		    _ready = true;
		});

		closingEvent = new Signal2();
		closingEvent.on(function(event, stack) {
		    stack.push(function(next) {
		        engine.db.appState.save().then(function() {
		            next();
		        }, report);
		    });
		});

		win.expose('main', this);

		if (instance == null) {
		    instance = this;
		}
        else {
            throw 'Error: Only one instance of BPlayerMain can be constructed';
        }
	}

/* === Instance Methods === */

    /**
      * initialize [this] shit
      */
    private function init(cb : Void->Void):Void {
        onready( cb );

        // need to find a better way to do this
		browserWindow = BrowserWindow.getAllWindows()[0];

        //appDir = new AppDir();

        // handle pre-exit tasks
        var preCloseComplete:Bool = false;
        win.onbeforeunload = (untyped function(event : Dynamic) {
            if ( preCloseComplete ) {
                return null;
            }
            else {
                beforeUnload(event, function() {
                    preCloseComplete = true;
                    win.close();
                });
                return false;
            }
        });

        defer( start );
    }

	/**
	  * start the Application
	  */
	@:access( pman.db.StoredModel )
	override function start():Void {
		title = 'BPlayer';

        // create the PlayerPage
		playerPage = new PlayerPage( this );

		// when ready
		onready(function() {
		    var i = launchInfo;
            // await creation of Player
            playerPage.onPlayerCreated(function(p : Player) {
                // -- set pre-launch player flags
                if (i.argv.any.fn(_.isUri()||_.isPath())) {
                    p.flag('src', 'command-line-input');
                }

                // open the player page
                body.open( playerPage );
            });

            // await readiness of the Player
            playerPage.onPlayerReady(function(p : Player) {
                keyboardControls = new KeyboardControls();
                keyboardControls.bind();

                dragManager = new DragDropManager( this );
                dragManager.init();

                //test_bdc();
                test_streams();
            });
        });

		//__buildMenus();
        ipcCommands = new RendererIpcCommands( this );
        ipcCommands.bind();

        // request launch info from background
        defer(function() {
            ic.send('GetLaunchInfo', null, null, function(launchInfo) {
                _provideLaunchInfo( launchInfo );
            });
        });
	}

	function test_streams() {
	    var out = new tannus.stream.StreamOutput();

	    echo( out );
	}

    /**
      test the BDC (Binary Delimited-Chunk) format
     **/
	private function test_bdc() {
		//function read() {
            //var binData:ByteArray = Ct.readFile('./testbdc.dat');
            //binData.bigEndian = !binData.bigEndian;
            //echo( binData );

            //var parsed = edis.format.bdc.Reader.run({}, binData);
            //echo( parsed );
        //}

        //function write() {
            
        //}

        //TODO
	}

	/**
	  * quit this shit
	  */
	public inline function quit():Void {
		App.quit();
	}

    /**
      * send command to the main process, telling it to update the application menu
      */
	public inline function updateMenu():Void {
	    ic.send('UpdateMenu', null);
	}

	/**
	  * invoke task that tidies up the database
	  */
	public function cleanDatabase(?done : VoidCb):Void {
		//var cleanDb = new pman.async.tasks.CleanDatabase( db );
		//cleanDb.run( done );
	}

	/**
	  * invoke task that converts the entire contents of the database to a JSON object
	  */
	public function exportDatabase(?done : VoidCb):Void {
		//var exportDb = new pman.async.tasks.ExportDatabase( db );
		//exportDb.run( done );
	}

	/**
	  * create route to [path] on the HTTP server
	  */
	public function httpServe(path : Path):String {
	    throw 'Error: HTTP-serving is unimplemented';
	}

	/**
	  * display an error message
	  */
	public inline function errorMessage(error : Dynamic):Void {
		player.message({
			text: Std.string( error ),
			color: new Color(255, 0, 0),
			fontSize: '10pt'
		});
	}

	/**
	  * before the DOM gets unloaded
	  */
	public function beforeUnload(event:Dynamic, done:Void->Void):String {
	    var stack = new AsyncStack();
	    closingEvent.call(event, stack);
	    stack.run( done );
	    return '';
	}

	/**
	  * create and display a FileSystem 'save' dialog
	  */
	public function fileSystemSavePrompt(?options:FSSPromptOptions, ?callback:Null<Path>->Void):Void {
	    if (options == null) options = {};
	    Dialog.showSaveDialog(_convertFSSPromptOptions(options), function(name : Null<String>) {
	        var path:Null<Path> = (name != null ? new Path( name ) : null);
	        if (options.complete != null) {
	            options.complete( path );
	        }
	        if (callback != null) {
	            callback( path );
	        }
	    });
	}

	/**
	  * fill in missing fields on FSPromptOptions
	  */
	private function _fillFSPromptOptions(o : FSPromptOptions):FSPromptOptions {
		if (o.directory == null)
			o.directory = false;
		if (o.title == null)
			o.title = 'PMan FileSystem Prompt';
		return o;
	}

	/**
	  * convert FSPromptOptions to FileOpenOptions
	  */
	private function _convertFSPromptOptions(o : FSPromptOptions):FileOpenOptions {
		var res:FileOpenOptions = {
			title: o.title,
			buttonLabel: o.buttonLabel,
			defaultPath: o.defaultPath,
			filters: o.filters,
			properties: (o.directory ? [OpenDirectory] : [OpenFile, MultiSelections])
		};
		if (res.defaultPath == null) {
			//res.defaultPath = db.configInfo.lastDirectory;
			res.defaultPath = appState.misc.lastDirectory;
		}
		return res;
	}

    /**
      * convert FSSPromptOptions to FileDialogOptions
      */
	private function _convertFSSPromptOptions(o : FSSPromptOptions):FileDialogOptions {
	    var res:FileDialogOptions = {
            title: o.title,
            buttonLabel: o.buttonLabel,
            defaultPath: o.defaultPath,
            filters: o.filters
	    };
	    if (res.defaultPath == null) {
			//res.defaultPath = db.configInfo.lastDirectory;
			res.defaultPath = appState.misc.lastDirectory;
	    }
	    return res;
	}

	/**
	  * ensure that the app has been initialized before running [task]
	  */
	public function onready(task : Void->Void):Void {
	    if ( _ready ) {
	        defer( task );
	    }
        else {
            _rs.once( task );
        }
	}

	/**
	  * process the given LaunchInfo
	  */
	public function _provideLaunchInfo(info : RawLaunchInfo):Void {
	    // get LaunchInfo
	    launchInfo = LaunchInfo.fromRaw( info );

	    // parse the launch info
	    parseLaunchInfo( launchInfo );

        // initialize the database
        engine.init(function(?error) {
            if (error != null) {
                report( error );
            }
            else {
                _rs.fire();
            }
        });
	}

	/**
	  * parse the given launch info
	  */
	public function parseLaunchInfo(info: LaunchInfo):Void {
	    echo( info );

	    try {
	        Sys.setCwd( info.cwd );
	    }
	    catch (error: Dynamic) {
	        //TODO
	    }
	}

	/**
	  * map the given Array to an Array of URIs
	  */
	private function toUris(a : Array<String>):Array<String> {
	    return a.map.fn(_.toMediaSource()).map.fn(_.toUri());
	}

    /**
      * resolve [p] to an absolute path
      */
	private function rta(p:Path, cwd:Path, env:Map<String, String>):Path {
	    if ( p.absolute ) {
	        return p;
	    }

	    var paths:Array<Path> = [cwd];
	    if (env.exists('PATH')) {
	        paths = paths.concat(env['PATH'].split(';').map.fn(Path.fromString(_)));
	    }
	    for (path in paths) {
	        var rr = path.resolve( p );
	        if (FileSystem.exists( rr )) {
	            return rr;
	        }
	    }
	    return null;
	}

/* === Compute Instance Fields === */

    // reference to the Player object
	public var player(get, never):Player;
	private inline function get_player():Null<Player> {
	    return (playerPage != null ? playerPage.player : null);
    }

    public var appDir(get, never):AppDir;
    private inline function get_appDir() return engine.appDir;
    
    public var db(get, never):PManDatabase;
    private inline function get_db() return engine.db;

    public var ic(get, never):RendererIpcCommands;
    private inline function get_ic() return ipcCommands;

/* === Instance Fields === */

    public var engine : Engine;
	public var playerPage : Null<PlayerPage>;
	public var browserWindow : BrowserWindow;
	//public var keyboardCommands : KeyboardCommands;
	public var keyboardControls : KeyboardControls;
	//public var appDir : AppDir;
	//public var db : PManDatabase;
	public var dragManager : DragDropManager;
	public var tray : Tray;
	public var ipcCommands : RendererIpcCommands;
	public var closingEvent : Signal2<Dynamic, AsyncStack>;
	public var launchInfo : LaunchInfo;

	private var _ready : Bool;
	// ready signal
	private var _rs : VoidSignal;

/* === Class Methods === */

	/* main function */
	public static function main():Void {
	    var app = new BPlayerMain();
	    app.init(function() {
	        //
	    });
	}

/* === Static Fields === */

    public static var instance : Null<BPlayerMain> = null;
}

typedef FSSPromptOptions = {
    ?title:String,
    ?defaultPath:String,
    ?buttonLabel:String,
    ?filters:Array<FileFilter>,
    ?complete:Null<Path>->Void
};

typedef FSPromptOptions = {
	?title:String,
	?defaultPath:String,
	?buttonLabel:String,
	?filters:Array<FileFilter>,
	?directory:Bool
};
