package ;

import tannus.io.*;
import tannus.ds.*;
import tannus.math.Random;
import tannus.graphics.Color;

import crayon.*;

import electron.ext.*;
import electron.ext.Dialog;
import electron.ext.MenuItem;
import electron.ipc.*;
import electron.ipc.IpcAddressType;
import electron.ipc.IpcTools.*;

import pman.core.*;
import pman.ui.*;
import pman.db.*;
import pman.events.*;
import pman.media.*;

import Std.*;
import tannus.internal.CompileTime in Ct;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;

class BPlayerMain extends Application {
	/* Constructor Function */
	public function new():Void {
		super();
	}

/* === Instance Methods === */

	/**
	  * start the Application
	  */
	override function start():Void {
		title = 'BPlayer';

		appDir = new AppDir( this );
		db = new PManDatabase( this );
		db.init(function() {
			trace('Database initialized');
		});

		browserWindow = BrowserWindow.getAllWindows()[0];
		playerPage = new PlayerPage( this );

		body.open( playerPage );

		__buildMenus();

		keyboardCommands = new KeyboardCommands( this );
		keyboardCommands.bind();

		dragManager = new DragDropManager( this );
		dragManager.init();

		initTray();
	}

	

	/**
	  * quit this shit
	  */
	public function quit():Void {
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
		Dialog.showOpenDialog(_convertFSPromptOptions(_fillFSPromptOptions( options )), function(paths : Array<String>):Void {
			callback( paths );
		});
	}

    /**
	  * open PornHub window
	  */
	private function initTray():Void {
		tray = new Tray(NativeImage.createFromPath(App.getAppPath().plusString('assets/icon32.png')));

        // build main menu part
		var trayMenu:Menu = Menu.buildFromTemplate(Ct.executeFile( 'res/trayTemplate.js' ));
		
		tray.setContextMenu( trayMenu );
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
		return res;
	}

/* === Compute Instance Fields === */

	public var player(get, never):Player;
	private inline function get_player():Player return playerPage.player;

/* === Instance Fields === */

	public var playerPage : PlayerPage;
	public var browserWindow : BrowserWindow;
	public var keyboardCommands : KeyboardCommands;
	public var appDir : AppDir;
	public var db : PManDatabase;
	public var dragManager : DragDropManager;
	public var tray : Tray;

/* === Class Methods === */

	/* main function */
	public static function main():Void {
		new BPlayerMain().start();
	}
}

typedef FSPromptOptions = {
	?title:String,
	?defaultPath:String,
	?buttonLabel:String,
	?filters:Array<FileFilter>,
	?directory:Bool
};
