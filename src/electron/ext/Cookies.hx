package electron.ext;

import haxe.extern.*;

import tannus.node.EventEmitter;
import tannus.node.Buffer;

extern class Cookies {
	function get(filter:CookiesGetFilter, callback:Null<Dynamic>->Array<Cookies>->Void):Void;
	function set(details:CookiesSetDetails, callback:Null<Dynamic>->Void):Void;
	function remove(url:String, name:String, done:Void->Void):Void;
}

typedef CookiesSetDetails = {
	url : String,
	?name : String,
	?value : String,
	?domain : String,
	?path : String,
	?secure : Bool,
	?httpOnly : Bool,
	?expirationDate : Float
};

typedef CookiesGetFilter = {
	?url : String,
	?name : String,
	?domain : String,
	?path : String,
	?secure : Bool,
	?session : Bool
};
