package electron.ipc;

import tannus.io.*;
import tannus.ds.*;

import electron.ext.IpcMain.IpcMainEvent in IpcEvent;
import electron.ext.IpcMain in Ipc;
import electron.ext.BrowserWindow;
import electron.ext.WebContents;
import electron.ipc.IpcAddressType;
import electron.ipc.IpcBusPacket;

import haxe.Serializer;
import haxe.Unserializer;

import Std.*;
import tannus.math.TMath.*;
import electron.Tools.defer;
import electron.ipc.IpcTools.*;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;
using electron.ipc.IpcTools;

class IpcBus_Main extends IpcBus {
	/* Constructor Function */
	public function new():Void {
		super();
	}

/* === Instance Methods === */

	// initialize [this]
	override function __init():Void {
		addressType = TMain;

		// standard asynchronous messages
		Ipc.on(IpcBus.GCN, __incoming_raw);
		// synchronous 'connect' messages
		Ipc.on((IpcBus.GCN + '-sync'), __incoming_raw_sync);
	}

	/**
	  * deliver the given Message
	  */
	private function deliver(msg : IpcMessage):Void {
		var socket:Null<IpcSocket> = sockets.get(msg.getRecipientId());
		if (socket != null) {
			socket._deliver( msg );
		}
		else {
			throw 'Error: Socket not found';
		}
	}

	// handle incoming messages (all)
	private function __incoming_raw(event:IpcEvent, values:Array<Dynamic>):Void {
		if (values.length > 0 && is(values[0], String)) {
			try {
				var str_data:String = values[0];
				var data:Dynamic = Unserializer.run( str_data );
				if (is(data, IpcBusPacket)) {
					__incoming_packet(event, cast(data, IpcBusPacket));
				}
			}
			catch(error : Dynamic) {
				return ;
			}
		}

		//event.returnValue = null;
	}

	/**
	  * handle incoming meta-packets sent synchronously
	  */
	private function __incoming_raw_sync(event:IpcEvent, values:Array<Dynamic>):Void {
		trace( values );
		if (values.length > 0 && is(values[0], String)) {
			var data:Dynamic = Unserializer.run(string(values[0]));
			if (is(data, IpcBusPacket)) {
				var packet:IpcBusPacket = cast data;
				trace('packet: $packet');
				__incoming_packet(event, packet);
			}
			else {
				throw 'TypeError: The ${IpcBus.GCN}-sync channel is reserved by the internals of the sockets system';
			}
		}
		else {
			throw 'TypeError: Invalid input';
		}
	}

	// handle incoming messages verified to be IpcBusPacket instances
	private function __incoming_packet(event:IpcEvent, packet:IpcBusPacket):Void {
		switch ( packet ) {
			// incoming 'connect' request from [address]
			case Connect( address ):
				// validate the address
				var status:Bool = canConnectTo( address );
				// if validation successful
				if ( status ) {
					// create the Socket
					var socket = sockets[ address.id ];
					if (socket == null) {
						// register the Socket
						sockets[address.id] = socket = _socket( address );
					}
					// announce the Socket
					defer(function() {
						socketConnected.call( socket );
					});
				}
				// effectively 'return' [status]
				event.returnValue = status;

			// incoming message
			case Message( frozenMsg ):
				var message:IpcMessage = frozenMsg.thaw();
				deliver( message );
		}
	}

	/**
	  * create a Socket
	  */
	override function _socket(peer : IpcAddress):IpcSocket {
		return new IpcSocket_Main(this, _address( peer.id ), peer);
	}

	/**
	  * validate the given address
	  */
	 override function canConnectTo(a : IpcAddress):Bool {
		return true;
	}

	/**
	  * broadcast a Message
	  */
	override function _broadcast(message : IpcMessage):Void {
		switch ( message.address.type ) {
			case TBrowserWindow( windowId ):
				var window = BrowserWindow.fromId( windowId );
				if (window == null) {
					throw 'Error: Invalid window id $windowId';
				}
				else {
					_sendToBrowserWindow(window, message);
				}

			case TMain:
				trace('cum blisters');
		}
	}

	/**
	  * send a Message to the given BrowserWindow
	  */
	private function _sendToBrowserWindow(w:BrowserWindow, message:IpcMessage):Void {
		// initialize the Serializer
		var serializer:Serializer = new Serializer();
		serializer.useCache = serializer.useEnumIndex = true;

		// 'freeze' the Message object
		var frozenMsg:IpcFrozenMessage = message.freeze();
		
		// build the packet
		var packet:IpcBusPacket = IpcBusPacket.Message( frozenMsg );

		// 'freeze' the packet
		serializer.serialize( packet );
		var string_packet:String = serializer.toString();

		// send the packet
		w.webContents.send(IpcBus.GCN, [string_packet]);
	}

/* === Instance Fields === */
}
