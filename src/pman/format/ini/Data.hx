package pman.format.ini;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.*;

import pman.core.*;
import pman.media.*;

import Slambda.fn;

using StringTools;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.ds.StringUtils;
using Slambda;
using pman.media.MediaTools;

@:structInit
class INI {
	public var nodes : Array<ININode>;

	public function new(nodes:Array<ININode>):Void {
		this.nodes = nodes;
	}
	
	public function prop(name : String):Null<String> {
		for (n in nodes) {
			switch ( n ) {
				case INIProp( property ) if (property.name == name):
					return property.value;
				default:
					continue;
			}
		}
		return null;
	}

	public function section(name : String):Null<INI> {
		for (n in nodes) {
			switch ( n ) {
				case INISection(sectionName, body) if (sectionName == name):
					return {
						nodes: body
					};
				default:
					continue;
			}
		}
		return null;
	}

	public function props():Array<INIProp> {
		var result = [];
		for (n in nodes) switch ( n ) {
			case INIProp( property ):
				result.push( property );
			default:
				continue;
		}
		return result;
	}

	public function propsMap():Map<String, String> {
		var result = new Map();
		for (n in nodes) switch ( n ) {
			case INIProp( property ):
				result[property.name] = property.value;
			default:
				continue;
		}
		return result;
	}

	public function sections():Map<String, INI> {
		var result = new Map();
		for (n in nodes) switch ( n ) {
			case INISection(name, body):
				result[name] = new INI( body );
			default:
				continue;
		}
		return result;
	}
}

enum ININode {
	INIProp(property : INIProp);
	INIComment(text : String);
	INISection(name:String, body:Array<ININode>);
}

@:structInit
class INIProp {
	public var name : String;
	public var value : String;
}
