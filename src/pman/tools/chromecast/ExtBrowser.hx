package pman.tools.chromecast;

import tannus.node.EventEmitter;

@:jsRequire('chromecast-api', 'Browser')
extern class ExtBrowser extends EventEmitter {
	// constructor
	public function new():Void;
	public function update():Void;
	public function destroy():Void;
}
