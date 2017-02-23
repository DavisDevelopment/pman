package pman.core;

import tannus.io.*;
import tannus.ds.*;
import tannus.events.*;
import tannus.sys.*;

import pman.display.*;
import pman.display.media.*;
import pman.media.*;

import haxe.macro.Expr;
import haxe.macro.Context;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using haxe.macro.ExprTools;
using tannus.macro.MacroTools;

class PlayerTools {
	/**
	  * perform an action on the Session, but only if the Session has media attached to it
	  */
	public static macro function sim(player:Expr, restArgs:Array<Expr>) {
		var session = macro $player.session;
		var condition:ExprOf<Bool> = macro $session.hasMedia();
		var result:Expr = macro null;
		if (restArgs.length == 1) {
			var body:Expr = restArgs.shift();

			body = body.replace(macro _, macro $session.playbackDriver).replace(macro s_, session);

			result = macro if ( $condition ) {
				$body;
			};
		}
		else if (restArgs.length == 2) {
			var iftrue:Expr = restArgs.shift();
			var iffalse:Expr = restArgs.shift();

			iftrue = iftrue.replace(macro _, macro $session.playbackDriver).replace(macro s_, session);
			iffalse = iffalse.replace(macro _, macro $session.playbackDriver).replace(macro s_, session);

			result = macro if ( $condition ) {
				$iftrue;
			}
			else {
				$iffalse;
			};
		}
		return result;
	}

	/**
	  * test whether the given extension name is indicative of a video file
	  */
	public static function isVideoFileName(name : String):Bool {
		var videoFileNames:Array<String> = [
			'webm', 'mkv', 'flv', 'vob',
			'ogv', 'ogg', 'avi', 'mov', 'qt',
			'wmv', 'amv', 'mp4', 'm4p', 'm4v',
			'mpg', 'mp2', 'mpeg', 'mpe', 'mpv',
			'm2v', '3gp', '3g2'
		];
		return videoFileNames.has(name.afterLast( '.' ).toLowerCase());
	}
}
