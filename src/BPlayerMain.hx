package ;

import tannus.io.*;
import tannus.ds.*;
import tannus.math.Random;
import tannus.graphics.Color;
import tannus.node.ChildProcess;

import crayon.*;

import electron.ext.*;
import electron.ext.Dialog;
import electron.ext.MenuItem;
import electron.ipc.*;
import electron.ipc.IpcAddressType;
import electron.ipc.IpcTools.*;
import electron.Tools.defer;

import pman.core.*;
import pman.ui.*;
import pman.db.*;
import pman.events.*;
import pman.media.*;
import pman.ww.Worker;

import Std.*;
import tannus.internal.CompileTime in Ct;
import tannus.TSys as Sys;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;

class BPlayerMain extends Application {
	/* Constructor Function */
	public function new():Void {
		super();

		_ready = false;
		_rs = new VoidSignal();
		_rs.once(function() {
		    _ready = true;
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

        appDir = new AppDir( this );

        db = new PManDatabase();
        db.init(function() {
            _rs.fire();
        });
    }

	/**
	  * start the Application
	  */
	@:access( pman.db.StoredModel )
	override function start():Void {
		title = 'BPlayer';

		playerPage = new PlayerPage( this );

		body.open( playerPage );

		keyboardCommands = new KeyboardCommands( this );
		keyboardCommands.bind();

		dragManager = new DragDropManager( this );
		dragManager.init();

		__buildMenus();

        var argv = Sys.args();
        trace( argv );
	}

	/**
	  * quit this shit
	  */
	public inline function quit():Void {
		App.quit();
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
	  * create and display FileSystem prompt
	  */
	public inline function fileSystemPrompt(options:FSPromptOptions, callback:Array<String>->Void):Void {
		Dialog.showOpenDialog(_convertFSPromptOptions(_fillFSPromptOptions( options )), function(paths : Null<Array<String>>):Void {
		    if (paths == null) {
		        paths = [];
		    }

			var mr:Null<String> = paths.last();
			if (mr != null) {
			    trace('lastDirectory: $mr');
			    db.configInfo.lastDirectory = mr;
			}

			callback( paths );
		});
	}

	/**
	  * create [this] Window's Toolbar Menu
	  */
	private function __buildMenus():Void {
		// wait for the Player to be ready
		player.onReady(function() {
			// create toolbar menu
			var items : Array<MenuItem> = new Array();
			var mediaItem:MenuItem = new MenuItem({
				label : 'Media',
				submenu : [
				{
					label: 'Open File(s)',
					//accelerator: 'CtrlOrCmd+O',
					click: function(item, window, event) {
						player.selectAndOpenFiles();
						//player.selectFilesToPlaylist(function( tracks ) {
							//player.addItemList( tracks );
						//});
					}
				},
				{
					label: 'Open Directory',
					//accelerator: 'CtrlOrCmd+F',
					click: function(item, window, event) {
						player.selectAndOpenDirectory();
					}
				},
				{type: 'separator'},
				{
					label: 'Save Playlist',
					click: function(item, window, event) {
					    player.savePlaylist();
					}
				}
				]
			});
			items.push( mediaItem );

            /*
               View Menu Item
            */
			var viewItem = new MenuItem({
				label: 'View',
				submenu: [
				{
					label: 'Playlist',
					//accelerator: 'CtrlOrCmd+L',
					click: function(item, window, event) {
						player.togglePlaylist();
					}
				}
				]
			});
			items.push( viewItem );

            /*
               Playlist Menu Item
            */
			var plItem = new MenuItem({
                label: 'Playlist',
                submenu: [
                {
                    label: 'Clear Playlist',
                    click: function(i,w,e){
                        player.clearPlaylist();
                    }
                },
                {
                    label: 'Shuffle Playlist',
                    click: function(i,w,e){
                        var pl = player.session.playlist.toArray();
                        player.clearPlaylist();
                        var r = new Random();
                        for (i in 0...r.randint(1, 3)) {
                            r.ishuffle( pl );
                        }
                        player.addItemList( pl );
                    }
                },
                {
                    label: 'Save Playlist',
                    click: function(i,w,e){
                        player.savePlaylist();
                    }
                }
                ]
			});
			items.push( plItem );

            /*
               Sessions Menu Item
            */
            var sessItemOpts:MenuItemOptions = {
                label: 'Sessions',
                //accelerator: 'Ctrl+S',
                submenu: [
                {
                    label: 'Save Current Session',
                    click: function(i,w,e){
                        player.saveState();
                    }
                },
                {type: 'separator'}
                ]
            };
            var sil:Array<MenuItemOptions> = sessItemOpts.submenu;
            var sessNames = appDir.allSavedSessionNames();
            for (name in sessNames) {
                var sessBtnOpts:MenuItemOptions = {
                    label: name,
                    click: function(i,w,e) {
                        player.loadState(name, function() {
                            player.message('$name was restored');
                        });
                    }
                }
                sil.push( sessBtnOpts );
            }
            var sessItem:MenuItem = new MenuItem( sessItemOpts );
            items.push( sessItem );

			var toolbarMenu:Menu = new Menu();
			for (item in items) {
				toolbarMenu.append( item );
			}

			Menu.setApplicationMenu( toolbarMenu );
		});
	}

	/**
	  * fill in missing fields on FSPromptOptions
	  */
	private function _fillFSPromptOptions(o : FSPromptOptions):FSPromptOptions {
		if (o.directory == null)
			o.directory = false;
		if (o.title == null)
			o.title = 'BPlayer FileSystem Prompt';
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
		    res.defaultPath = db.configInfo.lastDirectory;
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

/* === Compute Instance Fields === */

    // reference to the Player object
	public var player(get, never):Player;
	private inline function get_player():Null<Player> {
	    return (playerPage != null ? playerPage.player : null);
    }

/* === Instance Fields === */

	public var playerPage : Null<PlayerPage>;
	public var browserWindow : BrowserWindow;
	public var keyboardCommands : KeyboardCommands;
	public var appDir : AppDir;
	public var db : PManDatabase;
	public var dragManager : DragDropManager;
	public var tray : Tray;

	private var _ready : Bool;
	// ready signal
	private var _rs : VoidSignal;

/* === Class Methods === */

	/* main function */
	public static function main():Void {
	    var app = new BPlayerMain();
	    app.init( app.start );
	}

/* === Static Fields === */

    public static var instance : Null<BPlayerMain> = null;
}

typedef FSPromptOptions = {
	?title:String,
	?defaultPath:String,
	?buttonLabel:String,
	?filters:Array<FileFilter>,
	?directory:Bool
};
