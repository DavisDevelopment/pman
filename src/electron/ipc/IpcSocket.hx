package electron.ipc;

import tannus.io.*;
import tannus.ds.*;

import electron.ipc.IpcAddressType;

import Std.*;
import tannus.math.TMath.*;
import electron.ipc.IpcTools.*;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;
using electron.ipc.IpcTools;

@:access( tannus.io.EventDispatcher )
class IpcSocket {
	/* Constructor Function */
	public function new(address : IpcAddress):Void {
		this.address = address;
		
		ed = new EventDispatcher();
		ed.__checkEvents = false;
		awaitingReply = new Map();
	}

/* === Instance Methods === */

	/**
	  * register handler
	  */
	public function on(channel:String, handler:IpcMessage->Void):Void {
		ed.on(channel, handler);
	}

	/**
	  * register handler
	  */
	public function once(channel:String, handler:IpcMessage->Void):Void {
		ed.once(channel, handler);
	}

	/**
	  * method used by [this] Socket's bus to deliver messages to it
	  */
	@:allow( electron.ipc.IpcBus )
	private function _deliver(message : IpcMessage):Void {
		ni();
	}

	/**
	  * send a Message
	  */
	public function send(channel:String, data:Dynamic, ?onreply:Dynamic->Void):Void {
		// create the Message
		var message:IpcMessage = new IpcMessage(TNormal, channel, data, address, peerAddress);
		var messageId:String = message.id;
		if (onreply != null) {
			awaitingReply[messageId] = onreply;
		}

		// broadcast the Message
		bus._broadcast( message );
	}

	/**
	  * Helper method to send a reply Message
	  */
	private function sendReply(message:IpcMessage, data:Dynamic):Void {
		var replyMsg:IpcMessage = new IpcMessage(TReply, message.channel, data, message.address, message.sender);
		replyMsg.id = message.id;
		_deliver( replyMsg );
	}

/* === Instance Fields === */

	public var address : IpcAddress;
	public var peerAddress : IpcAddress;
	public var bus : IpcBus;

	private var ed : EventDispatcher;
	@:allow( electron.ipc.IpcBus )
	private var awaitingReply : Map<String, Any->Void>;

/* === Static Methods === */

	public static function create(address : IpcAddress):IpcSocket {
		switch ( address.type ) {
			case TMain:
				return new IpcSocket( address );

			case TBrowserWindow( windowId ):
				return new IpcSocket( address );
		}
	}
}
