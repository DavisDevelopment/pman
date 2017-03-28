package ;

import tannus.ds.*;
import tannus.ds.tuples.*;
import tannus.sys.Path;

import electron.main.*;
import electron.main.Menu;
import electron.main.MenuItem;
import electron.ext.App;
import electron.Tools.defer;

import js.html.Window;

import tannus.TSys as Sys;

import pman.db.AppDir;
import pman.ipc.MainIpcCommands;

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
	}

/* === Instance Methods === */

	/**
	 * start [this] Background script
	 */
	public function start():Void {
		App.onReady( _ready );
		App.onAllClosed( _onAllClosed );

		_listen();
	}

	/**
	  * open a new Player window
	  */
	public function openPlayerWindow(?cb : BrowserWindow -> Void):Void {
	    // create new hidden BrowserWindow
		var win:BrowserWindow = new BrowserWindow({
			show: false,
			icon: ap('assets/icon64.png').toString(),
			width: 640,
			height: 480
		});
		// load the html file onto that BrowserWindow
		var dir:Path = ap( 'pages/index.html' );
		win.loadURL( 'file://$dir' );
		// wait for the window to be ready
		win.once('ready-to-show', function() {
			win.show();
			win.maximize();
			win.focus();
			playerWindows.push( win );
			defer(function() {
                if (cb != null) {
                    cb( win );
                }
                win.webContents.openDevTools();
            });
		});
	}

	/**
	  * build the menu
	  */
	public function buildMenu():Menu {
	    var menu:Menu = new Menu();

	    var media = new MenuItem({
            label: 'Media',
            submenu: [
            {
                label: 'Open File(s)',
                click: function(i:MenuItem, w:BrowserWindow) {
                    ic.send(w, 'OpenFile');
                }
            },
            {
                label: 'Open Directory',
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
                click: function(i, w:BrowserWindow) {
                    ic.send(w, 'TogglePlaylist');
                }
            }
            ]
	    });
	    menu.append( viewItem );

	    var playlist = new MenuItem({
            label: 'Playlist',
            submenu: [
            {
                label: 'Clear Playlist',
                click: function(i, w) ic.send(w, 'ClearPlaylist')
            },
            {
                label: 'Shuffle Playlist',
                click: function(i, w) ic.send(w, 'ShufflePlaylist')
            },
            {
                label: 'Save Playlist',
                click: function(i, w) ic.send(w, 'SavePlaylist')
            }
            ]
	    });
	    menu.append( playlist );

	    var sessionOptions:Dynamic = {
            label: 'Session',
            submenu: [untyped
            {
                label: 'Save Current Session',
                click: function(i, w) ic.send(w, 'SaveSession')
            },
            {type: 'separator'}
            ]
	    };
	    var sessNames = appDir.allSavedSessionNames();
	    for (name in sessNames) {
	        sessionOptions.submenu.push({
                label: name,
                click: function(i, w) {
                    ic.send(w, 'LoadSession', [name]);
                }
	        });
	    }
	    var session = new MenuItem( sessionOptions );
	    menu.append( session );

	    return menu;
	}

	/**
	  * Update the application menu
	  */
	public function updateMenu():Void {
	public inline function updateMenu():Void {
	    Menu.setApplicationMenu(buildMenu());
	}

/* === Event Handlers === */

	/**
	 * when the Application is ready to start doing stuff
	 */
	private function _ready():Void {
		trace(' -- background process ready -- ');

		updateMenu();
		
		openPlayerWindow(function( bw ) {
			null;
		});
	}

	/**
	  * when a window closes
	  */
	private function _onAllClosed():Void {
	    App.quit();
	}

/* === Utility Methods === */

	private function ap(?s : String):Path {
		var p:Path = (_p != null ? _p : (_p = App.getAppPath()));
		if (s != null)
			p = p.plusString( s );
		return p;
	}

	private inline function uip(?s:String):Path {
	    return (s==null?App.getPath(UserData):App.getPath(UserData).plusString(s));
	}

/* === Computed Instance Fields === */

    public var ic(get, never):MainIpcCommands;
    private inline function get_ic() return ipcCommands;

/* === Instance Fields === */

	public var playerWindows : Array<BrowserWindow>;
	public var ipcCommands : MainIpcCommands;
	public var appDir : AppDir;
	private var _p:Null<Path> = null;

	/* === Class Methods === */

	public static function main():Void {
		new Background().start();
	}
}
