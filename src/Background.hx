package ;

import tannus.ds.*;
import tannus.ds.tuples.*;
import tannus.sys.Path;
import tannus.node.Fs as NodeFs;
import tannus.sys.FileSystem as Fs;

import electron.main.*;
import electron.main.Menu;
import electron.main.MenuItem;
import electron.main.Session;
import electron.NativeImage;

import js.html.Window;

import tannus.TSys as Sys;

import edis.libs.electron.App;
import edis.Globals.*;

import pman.LaunchInfo;
import pman.db.AppDir;
import pman.ipc.MainIpcCommands;
import pman.ww.*;
//import pman.server.*;
import pman.tools.ArgParser;
import pman.tools.DirectiveSpec;
import pman.tools.Directive;
import pman.tools.DirectiveExecutor;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;
using pman.bg.DictTools;

class Background {
	/* Constructor Function */
	public function new():Void {
		playerWindows = new Array();
		ipcCommands = new MainIpcCommands( this );
		ipcCommands.bind();
		appDir = new AppDir();
		//server = new Server( this );
		argParser = new ArgParser();
	}

/* === Instance Methods === */

	/**
	 * start [this] Background script
	 */
	public function start():Void {
        parseArgs(Sys.args());

        // fixed SingleInstance implementation
		var notFirst = App.makeSingleInstance( _onSecondaryLaunch );
		if ( notFirst ) {
		    App.exit( 0 );
		}

		App.onReady( _ready );
		App.onAllClosed( _onAllClosed );

		_listen();
	}

    /**
      * stop the background script
      */
	public function close():Void {
		//if (server != null)
            //server.close();
	    App.quit();
	}

    /**
      * stop [this] application immediately
      */
	public inline function exit(code:Int=0):Void {
	    App.exit( code );
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
                session: Session.fromPartition('persist:pman', {
                    cache: true
                }),
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
		    #if !release
			win.webContents.openDevTools({
                mode: 'bottom'
			});
		    #end
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
	    inline function tap(n:String) ic.push( n );
	    var call:Dynamic = ic.call;
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
                click: function(i,w) {
                    /* FIXME
                    ic.send(w, 'EditPreferences');
                    */
                    tap( 'EditPreferences' );
                }
            },
            {
                label: 'About',
                click: function(i, w) {
                    /* FIXME
                    ic.notify({
                        text: 'betty',
                        duration: 60000,
                        color: '#28e63f',
                        backgroundColor: '#222222',
                        fontSize: '16pt'
                    });
                    */
                    browserOpen( 'https://github.com/DavisDevelopment/pman' );
                }
            },
            {
                label: 'Help',
                click: function(i, w) {
                    /* FIXME
                    ic.notify({
                        text: 'you require help?\n\n\n - git gud',
                        duration: 60000,
                        color: '#28e63f',
                        backgroundColor: '#222222',
                        fontSize: '16pt'
                    });
                    */
                    browserOpen( 'https://github.com/DavisDevelopment/pman/wiki/Help' );
                }
            },
            {type: 'separator'},
            {
                label: 'Reload',
                accelerator: 'CommandOrControl+R',
                click: function() {
                    App.relaunch();
                    for (win in playerWindows) {
                        win.close();
                    }
                    defer( close );
                }
            },
            {
                label: 'Quit',
                accelerator: 'CommandOrControl+Q',
                click: function() {
                    close();
                }
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
                    /* FIXME
                    ic.send(w, 'OpenFile');
                    */
                    tap( 'OpenFile' );
                }
            },
            {
                label: 'Open Directory',
                accelerator: 'CommandOrControl+F',
                click: function(i:MenuItem, w:BrowserWindow) {
                    /* FIXME
                    ic.send(w, 'OpenDirectory');
                    */
                    tap( 'OpenDirectory' );
                }
            },
            {type: 'separator'},
            {
                label: 'Save Playlist',
                click: function(i, w:BrowserWindow) {
                    /* FIXME
                    ic.send(w, 'SavePlaylist');
                    */
                    tap( 'SavePlaylist' );
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
                    /* FIXME
                    ic.send(w, 'TogglePlaylist');
                    */
                    tap( 'TogglePlaylist' );
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
                click: function(i, w) {
                    /* FIXME
                    ic.send(w, 'ClearPlaylist');
                    */
                    tap( 'ClearPlaylist' );
                }
            },
            {
                label: 'Shuffle',
                click: function(i, w) {
                    /* FIXME
                    ic.send(w, 'ShufflePlaylist');
                    */
                    tap( 'ShufflePlaylist' );
                }
            },
            {
                label: 'Save',
                accelerator: 'CommandOrControl+S',
                click: function(i, w) {
                    /* FIXME
                    ic.send(w, 'SavePlaylist', [false]);
                    */
                    call('SavePlaylist', false);
                }
            },
            {
                label: 'Save As',
                accelerator: 'CommandOrControl+Shift+S',
                click: function(i, w) {
                    /* FIXME
                    ic.send(w, 'SavePlaylist', [true]);
                    */
                    call('SavePlaylist', true);
                }
            },
            {
                label: 'Export',
                click: function(i, w) {
                    /* FIXME
                    ic.send(w, 'ExportPlaylist');
                    */
                    tap('ExportPlaylist');
                }
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
                        /* FIXME
                        ic.send(w, 'LoadPlaylist', [name]);
                        */
                        call('LoadPlaylist', name);
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
                click: function(i,w) {
                    /* FIXME
                    ic.send(w, 'Snapshot');
                    */
                    tap( 'Snapshot' );
                }
            },
            {type: 'separator'},
            {
                label: 'Bookmarks',
                click: function(i,w) {
                    /* FIXME
                    ic.send(w, 'EditMarks');
                    */
                    tap( 'EditMarks' );
                }
            },
            {type: 'separator'},
            {
                label: 'Scripts',
                submenu: [
                {
                    label: 'Skim Media',
                    click: function(i,w) {
                        /* FIXME
                        ic.send(w, 'AddComponent', untyped ['skim']);
                        */
                        call('AddComponent', 'skim');
                    }
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

        if (!shouldOpen || playerWindows.length == 0) {
            var openPman = new MenuItem({
                label: 'Open PMan',
                click: function(i, w) {
                    updateMenu();
                    if (playerWindow == null) {
                        openPlayerWindow(function(bw) {
                            //didit
                        });
                    }
                    else {
                        playerWindow.focus();
                    }
                }
            });
            menu.append( openPman );
        }

        var openFiles = new MenuItem({
            label: 'Open Files',
            click: function(i, w) {
                ic.send(w, 'OpenFile');
            }
        });
        menu.append( openFiles );

        var openDir = new MenuItem({
            label: 'Open Directory',
            click: function(i, w) {
                ic.send(w, 'OpenDirectory');
            }
        });
        menu.append( openDir );
        menu.append(new MenuItem({type: 'separator'}));
        menu.append(new MenuItem({
            label: 'Quit PMan',
            click: function(i, w) close()
        }));

	    return menu;
	}

    /**
      * update the Tray
      */
    public function updateTray():Void {
        if (tray == null) {
            var trayIconPath = ap('assets/icon64.png');
            if (Sys.systemName() == 'Linux' && App.isUnityRunning()) {
                trayIconPath = ap('assets/gray-icon64.png');
            }
            tray = new Tray(trayIconPath.toString());
        }

        tray.setToolTip('PMan');
        tray.setContextMenu(buildTrayMenu());
    }

	/**
	  * Get launch info
	  */
	public function launchInfo():RawLaunchInfo {
	    var cwd = Sys.getCwd();
        //var paths = argParser.paths;
        var argv = Sys.args();
        var env = MapTools.toObject(Sys.environment());

	    return {
            cwd: cwd,
            env: env,
            argv: argv
            //paths: paths.map.fn(_.toString())
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
        //if (server == null) {
            //server = new Server( this );
            //server.init();
        //}
        //return server.serve( path );
        return 'not today, sir';
    }

    /**
      * open the given URL in the user's browser
      */
    public inline function browserOpen(url: String):Void {
        electron.Shell.openExternal( url );
    }

    /**
      * parse command-line arguments
      */
    private function parseArgs(argv : Array<String>):Void {
        handleSpecialArgs( argv );

        var spec = argParser.parse( argv );
        trace( spec );
        var executor = new DirectiveExecutor(clapi());
        executor.exec( spec );
    }

    /**
      * command-line-api initialization
      */
    private function clapi():DirectiveSpec {
        var spec = new DirectiveSpec('[toplevel]');
        spec.flag('background-only');
        spec.executor(function(c, argv, flags, params) {
            if (flags.exists('background-only')) {
                shouldOpen = false;
                trace('GET MY URINAL');
            }
        });
        spec.sub('betty', function(betty) {
            betty.flag('--urinal');
            betty.executor(function(c, argv, flags, params) {
                trace('WAEL!');
            });
        });
        return spec;
    }

    /**
      * handle special command-line arguments used during or immediately after installation
      */
    private function handleSpecialArgs(argv: Array<String>):Void {
        if (argv[0] == '--debian-install') {
            shouldOpen = false;
        }
        else if (argv.length == 2) {
            var squirrelEvent = argv[1];
            switch ( squirrelEvent ) {
                case '--squirrel-install', '--squirrel-updated':
                    //TODO at least create a shortcut
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

        updateTray();

        if ( shouldOpen ) {
            updateMenu();
            openPlayerWindow(function( bw ) {
                //server.init();
            });
        }

        #if release
        var pmanAutoLauncher = Type.createInstance(js.Lib.require('auto-launch'), [{
            name: 'PMan'
        }]);
        var bp:Promise<Bool> = Promise.fromJsPromise(pmanAutoLauncher.isEnabled());
        bp.then(function(isEnabled) {
            if ( !isEnabled ) {
                pmanAutoLauncher.enable();
            }
        }).unless(function(error) {
            trace( error );
        });
        #end
	}

	/**
	  * when a window closes
	  */
	private function _onAllClosed():Void {
	    playerWindows = new Array();
	    updateTray();
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
	//public var server : Null<Server> = null;
	private var _p:Null<Path> = null;
	private var argParser : ArgParser;
	private var shouldOpen: Bool = true;

	/* === Class Methods === */

	public static function main():Void {
		new Background().start();
	}
}
