package ;

import tannus.ds.tuples.*;
import tannus.sys.Path;

import electron.ext.*;
import electron.ipc.*;

class Background {
	/* Constructor Function */
	public function new():Void {
		ipcBus = IpcBus.get();
	}

/* === Instance Methods === */

	/**
	  * start [this] Background script
	  */
	public function start():Void {
		App.onReady(function() {
			var appDir = App.getAppPath();
			var win = new BrowserWindow({
				icon: appDir.plusString('assets/icon64.png').toString(),
				show: false,
				width: 640,
				height: 480
			});
			var dir:Path = appDir.plusString( 'pages/index.html' );
			win.loadURL( 'file://$dir' );
			win.once('ready-to-show', function() {
				win.show();
				win.maximize();
				//win.webContents.openDevTools();
				win.focus();
			});
		});

		//ipcBus.socketConnected.on( onSocketConnected );
	}

	/**
	  * Build the application's Tray
	  */
	private function initTray():Void {
		var appDir = App.getAppPath();
		var icon = NativeImage.createFromPath(appDir.plusString('assets/icon32.png').toString());
		var tray = new Tray( icon );
		var trayMenu = Menu.buildFromTemplate([
			{
				label: 'Test Button'
			}
		]);
		tray.setContextMenu( trayMenu );
	}

	/**
	  * initialize a newly connected socket
	  */
	private function onSocketConnected(socket : IpcSocket):Void {
		socket.send('test', 'message from main process', function( response ) {
			trace('reply: ${response}');
		});
	}

/* === Instance Fields === */

	public var ipcBus : IpcBus;

/* === Class Methods === */

	public static function main():Void {
		new Background().start();
	}
}
