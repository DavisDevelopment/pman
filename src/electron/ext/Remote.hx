package electron.ext;

@:jsRequire('electron', 'remote')
extern class Remote {
	public static function require(name : String):Dynamic;
	public static function getCurrentWindow():BrowserWindow;
	public static function getCurrentWebContents():WebContents;
}
