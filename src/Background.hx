package ;

import tannus.ds.*;
import tannus.ds.tuples.*;
import tannus.sys.Path;

import electron.ext.*;
import electron.Tools.defer;

class Background {
	/* Constructor Function */
	public function new():Void {
		playerWindows = new Array();
	}

	/* === Instance Methods === */

	/**
	 * start [this] Background script
	 */
	public function start():Void {
		App.onReady( _ready );
		App.onAllClosed( _onAllClosed );
	}

	/**
	  * open a new Player window
	  */
	public function openPlayerWindow(?cb : BrowserWindow -> Void):Void {
		var win:BrowserWindow = new BrowserWindow({
			show: false,
			icon: ap('assets/icon64.png').toString(),
			width: 640,
			height: 480
		});
		var dir:Path = ap( 'pages/index.html' );
		win.loadURL( 'file://$dir' );
		win.once('ready-to-show', function() {
			win.show();
			win.maximize();
			//win.webContents.openDevTools();
			win.focus();
			playerWindows.push( win );
			defer(function() {
                if (cb != null) {
                    cb( win );
                }
                #if debug
                win.webContents.openDevTools();
                #end
            });
		});
	}

	/* === Event Handlers === */

	/**
	 * when the Application is ready to start doing stuff
	 */
	private function _ready():Void {
		trace(' -- background process ready -- ');
		
        #if debug
            var dte:Object = BrowserWindow.getDevToolsExtensions();
            if (!dte.exists( 'kcdehbecimoacajfpcpihajfnbfpk' )) {
                BrowserWindow.addDevToolsExtension(uip('dev_extensions/kcdehbecimoacajfpcpihajfnbfpk').toString());
            }
        #end

		_ipcListen();

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

	/**
	 * listen for ipc messages
	 */
	private function _ipcListen():Void {
		IpcMain.on('command:open-window', function(event, values) {
			return ;
		});
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

	/* === Instance Fields === */

	public var playerWindows : Array<BrowserWindow>;
	private var _p:Null<Path> = null;

	/* === Class Methods === */

	public static function main():Void {
		new Background().start();
	}
}
