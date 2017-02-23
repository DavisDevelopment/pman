package ;

import tannus.node.Process;

class WorkerMain {
	/* Constructor Function */
	public function new():Void {

	}

/* === Instance Methods === */

	/**
	  * entry point for the app
	  */
	public function start():Void {
		listenForMessages( onmessage );
	}

	/**
	  * process incoming messages
	  */
	private function onmessage(raw : Dynamic):Void {
		trace( raw );
	}

	private inline function send(message : Dynamic):Void {
		(untyped __js__('process.send'))( message );
	}
	private inline function listenForMessages(handler : Dynamic -> Void):Void {
		(untyped __js__('process.on'))('message', handler);
	}

/* === Instance Fields === */

/* === Static Methods === */

	public static function main():Void {
		new WorkerMain().start();
	}
}
