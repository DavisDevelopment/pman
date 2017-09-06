package ;

import tannus.ds.*;
import tannus.ds.tuples.*;
import tannus.sys.Path;
import tannus.node.Fs as NodeFs;
import tannus.sys.FileSystem as Fs;

import electron.main.*;
import electron.main.Menu;
import electron.main.MenuItem;
import electron.NativeImage;
import electron.ext.App;
import electron.Tools.defer;

import js.html.Window;

import tannus.TSys as Sys;

import pman.LaunchInfo;
import pman.db.AppDir;
import pman.ipc.MainIpcCommands;
import pman.ww.*;
import pman.server.*;
import pman.tools.BackgroundArgParser;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;

class Background {
	/* Constructor Function */
	public function new():Void {
		playerWindows = new Array();
		ipcCommands = new MainIpcCommands( this );
		ipcCommands.bind();
		appDir = new AppDir();
		//server = new Server( this );
		argParser = new BackgroundArgParser();
	}

/* === Instance Methods === */

	/**
	 * start [this] Background script
	 */
	public function start():Void {

        parseArgs(Sys.args());

		App.onReady( _ready );
		App.onAllClosed( _onAllClosed );
		App.makeSingleInstance( _onSecondaryLaunch );

		_listen();
	}

    /**
      * stop the background script
      */
	public function close():Void {
	    if (server != null)
            server.close();
	    App.quit();
	}

	/**
	  * open a new Player window
	  */
	public function openPlayerWindow(?cb : BrowserWindow -> Void):Int {
	    // create new hidden BrowserWindow
	    var icon = NativeImage.createFromPath(ap('assets/icon64.png').toString());
		var win:BrowserWindow = new BrowserWindow({
			show: false,
			width: 640,
			height: 480,
			webPreferences: untyped {
                nodeIntegration: true,
                nodeIntegrationInWorker: true,
                webSecurity: false,
                experimentalFeatures: true,
                experimentalCanvasFeatures: true,
                blinkFeatures: [
                    'Accelerated2dCanvas',
                    'AudioWorklet'
                ].join(',')
			}
		});
		// load the html file onto that BrowserWindow
		var dir:Path = ap( 'pages/index.html' );
	    #if (release || compress)
	        dir = ap('pages/index.min.html');
	    #end
		win.loadURL( 'file://$dir' );
		win.setIcon( icon );
		playerWindows.push( win );
		
		// wait for the window to be ready
		win.once('ready-to-show', function() {
			win.show();
			win.maximize();
			win.focus();
			defer(function() {
                if (cb != null) {
                    cb( win );
                }
            });
		});

		return win.id;
	}

	/**
	  * build the menu
	  */
	public function buildToolbarMenu():Menu {
	    var menu:Menu = new Menu();

        var pman_item = new MenuItem({
            label: 'PMan',
            submenu: [
            {
                label: 'New Window',
                click: function(i, w) {
                    //TODO
                }
            },
            {type: 'separator'},
            {
                label: 'Preferences',
                click: function(i,w) ic.send(w, 'EditPreferences')
            },
            {
                label: 'About',
                click: function(i, w) {
                    ic.notify({
                        text: 'Taste of my anal syrup',
                        duration: 60000,
                        color: '#28e63f',
                        backgroundColor: '#222222',
                        fontSize: '16pt'
                    });
                }
            },
            {
                label: 'Help',
                click: function(i, w) {
                    ic.notify({
                        text: 'you require help?\n\n\n - git gud',
                        duration: 60000,
                        color: '#28e63f',
                        backgroundColor: '#222222',
                        fontSize: '16pt'
                    });
                }
            },
            {type: 'separator'},
            {
                label: 'Reload',
                accelerator: 'CommandOrControl+R',
                click: function() {
                    App.relaunch();
                    close();
                }
            },
            {
                label: 'Quit',
                accelerator: 'CommandOrControl+Q',
                click: function() close()
            }
            ]
        });
        menu.append( pman_item );

	    var media = new MenuItem({
            label: 'Media',
            submenu: [
            {
                label: 'Open File(s)',
                accelerator: 'CommandOrControl+O',
                click: function(i:MenuItem, w:BrowserWindow) {
                    ic.send(w, 'OpenFile');
                }
            },
            {
                label: 'Open Directory',
                accelerator: 'CommandOrControl+F',
                click: function(i:MenuItem, w:BrowserWindow) {
                    ic.send(w, 'OpenDirectory');
                }
            },
            {type: 'separator'},
            {
                label: 'Save Playlist',
                click: function(i, w:BrowserWindow) {
                    ic.send(w, 'SavePlaylist');
                }
            }
            ]
	    });
	    menu.append( media );

	    var viewItem = new MenuItem({
            label: 'View',
            submenu: [
            {
                label: 'Playlist',
                accelerator: 'CommandOrControl+L',
                click: function(i, w:BrowserWindow) {
                    ic.send(w, 'TogglePlaylist');
                }
            },
            {
                label: 'Inspect Application',
                accelerator: 'CommandOrControl+Shift+J',
                click: function(i, w:BrowserWindow) {
                    w.webContents.toggleDevTools();
                }
            }
            ]
	    });
	    menu.append( viewItem );

	    var playlistOptions:Dynamic = {
            label: 'Playlist',
            submenu: untyped [
            {
                label: 'Clear',
                accelerator: 'CommandOrControl+W',
                click: function(i, w) ic.send(w, 'ClearPlaylist')
            },
            {
                label: 'Shuffle',
                click: function(i, w) ic.send(w, 'ShufflePlaylist')
            },
            {
                label: 'Save',
                accelerator: 'CommandOrControl+S',
                click: function(i, w) ic.send(w, 'SavePlaylist', [false])
            },
            {
                label: 'Save As',
                accelerator: 'CommandOrControl+Shift+S',
                click: function(i, w) ic.send(w, 'SavePlaylist', [true])
            },
            {
                label: 'Export',
                click: function(i, w) ic.send(w, 'ExportPlaylist')
            }
            ]
	    };

	    var playlist = new MenuItem( playlistOptions );
	    menu.append( playlist );

	    var splNames = appDir.allSavedPlaylistNames();
	    if (splNames.length > 0) {
            var playlistsOptions:Dynamic = {
                label: 'Playlists',
                submenu: []
            };

            for (name in splNames) {
                playlistsOptions.submenu.push({
                    label: name,
                    click: function(i, w) {
                        ic.send(w, 'LoadPlaylist', [name]);
                    }
                });
            }

            var playlists = new MenuItem( playlistsOptions );
            menu.append( playlists );
        }

	    var tools = new MenuItem({
            label: 'Tools',
            submenu: [
            {
                label: 'Take Snapshot',
                click: function(i,w) ic.send(w, 'Snapshot')
            },
            {type: 'separator'},
            {
                label: 'Bookmarks',
                click: function(i,w) ic.send(w, 'EditMarks')
            },
            {type: 'separator'},
            {
                label: 'Scripts',
                submenu: [
                {
                    label: 'Skim Media',
                    click: function(i,w) ic.send(w, 'AddComponent', untyped ['skim'])
                }
                ]
            }
            ]
	    });
	    menu.append( tools );

	    return menu;
	}

	/**
	  * Update the application menu
	  */
	public inline function updateMenu():Void {
	    Menu.setApplicationMenu(buildToolbarMenu());
	}

	/**
	  * build the Tray menu
	  */
	public function buildTrayMenu():Menu {
	    var menu = new Menu();



	    return menu;
	}

	/**
	  * Get launch info
	  */
	public function launchInfo():RawLaunchInfo {
	    var cwd = Sys.getCwd();
        var paths = argParser.paths;
        var env = MapTools.toObject(Sys.environment());

	    return {
            cwd: cwd,
            env: env,
            paths: paths.map.fn(_.toString())
	    };
	}

	/**
	  * bind event handlers
	  */
	private function _listen():Void {
	    _watchFiles();
	}

	/**
	  * watch some files for stuff
	  */
	private function _watchFiles():Void {
	    var plPath = appDir.playlistsPath();
	    if (!Fs.exists(plPath.toString())) {
	        Fs.createDirectory(plPath.toString());
	    }

	    var plw = NodeFs.watch(plPath.toString(), _playlistFolderChanged);
	}

/* === Event Handlers === */

    /**
      * handle signal from player window to add route to given path
      */
    public function httpServe(path : Path):String {
        if (server == null) {
            server = new Server( this );
            server.init();
        }
        return server.serve( path );
    }

    /**
      * parse command-line arguments
      */
    private function parseArgs(argv : Array<String>):Void {
        argParser.parse( argv );
    }

    /**
      * handle Squirrel events passed to [this] app
      */
    private function _handleSquirrelEvents():Void {
        var argv = Sys.args();
        if (argv.length == 2) {
            var squirrelEvent = argv[1];
            switch ( squirrelEvent ) {
                case '--squirrel-install', '--squirrel-updated':
                    //TODO perform installation operations
                    close();

                default:
                    return ;
            }
        }
    }

	/**
	 * when the Application is ready to start doing stuff
	 */
	private function _ready():Void {
	    #if release
	        null;
	    #else
            trace(' -- background process ready -- ');
        #end

		updateMenu();

		openPlayerWindow(function( bw ) {
			//server.init();
		});
	}

	/**
	  * when a window closes
	  */
	private function _onAllClosed():Void {
	    close();
	}

	/**
	  * when an attempt is made to launch a second instance of [this] application
	  */
	private function _onSecondaryLaunch(args:Array<String>, scwd:String):Void {
		//var info = launchInfo();
		//ic.send(playerWindow, 'LaunchInfo', [info]);
	}

	/**
	  * when the playlist folder changes
	  */
	private function _playlistFolderChanged(eventName:String, filename:String):Void {
	    updateMenu();
	}

/* === Utility Methods === */

    /**
      * get paths descended from the application path
      */
	private function ap(?s : String):Path {
		var p:Path = (_p != null ? _p : (_p = App.getAppPath()));
		if (s != null)
			p = p.plusString( s );
		return p;
	}

    /**
      * get apps descended from the userdata path
      */
	private inline function uip(?s:String):Path {
	    return (s==null?App.getPath(UserData):App.getPath(UserData).plusString(s));
	}

/* === Computed Instance Fields === */

    public var ic(get, never):MainIpcCommands;
    private inline function get_ic() return ipcCommands;

    public var playerWindow(get, never):Null<BrowserWindow>;
    private inline function get_playerWindow() return playerWindows[0];

/* === Instance Fields === */

	public var playerWindows : Array<BrowserWindow>;
	public var ipcCommands : MainIpcCommands;
	public var appDir : AppDir;

	public var tray : Null<Tray> = null;
	public var server : Null<Server> = null;
	private var _p:Null<Path> = null;
	private var argParser : BackgroundArgParser;

	/* === Class Methods === */

	public static function main():Void {
		new Background().start();
	}
}
