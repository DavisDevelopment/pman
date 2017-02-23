package electron.ipc;

import tannus.io.*;
import tannus.ds.*;

import electron.ext.Remote;
import electron.ext.BrowserWindow;
import electron.ext.WebContents;
import electron.ext.IpcRenderer in Ipc;
import electron.ext.IpcRenderer.IpcRendererEvent in IpcEvent;
import electron.ext.IpcRenderer.IpcRendererMessageSender in MsgSrc;
import electron.ipc.IpcBusPacket;
import electron.ipc.IpcAddressType;

import haxe.Serializer;
import haxe.Unserializer;

import Std.*;
import tannus.math.TMath.*;
import foundation.Tools.defer;
import electron.ipc.IpcTools.*;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;

class IpcBus_Renderer extends IpcBus {
	/* Constructor Function */
	public function new():Void {
		super();

		__init();
	}

/* === Instance Methods === */

	/**
	  * initialize [this] Bus
	  */
	override function __init():Void {
		bw = Remote.getCurrentWindow();
		addressType = TBrowserWindow( bw.id );

		Ipc.on(IpcBus.GCN, __incoming_raw);
	}

	/**
	  * create new connection
	  */
	override function createSocket(id:String, ?peerType:IpcAddressType):IpcSocket {
		// given [peerType] a default value
		if (peerType == null) {
			peerType = TMain;
		}

		// create the packet
		var packet:IpcBusPacket = Connect(_address( id ));
		// freeze the packet
		var frozenPacket:String = serialize( packet );
		trace('packet: $frozenPacket');
		/*
		   send the packet
		   [status] will be true if the peer socket was created on the remote, and false otherwise
		*/
		var status:Bool = Ipc.sendSync((IpcBus.GCN + '-sync'), [frozenPacket]);
		trace('status: $status');

		// create the Socket if its peer has been created
		if ( status ) {
			// create the Socket
			var socket:IpcSocket = _socket(new IpcAddress(id, peerType));
			// register the Socket
			sockets[id] = socket;
			// announce the Socket
			defer(function() {
				socketConnected.call( socket );
			});
			return socket;
		}

		throw 'Error: Peer socket was not created';
	}

	/**
	  * broadcast a Message
	  */
	override function _broadcast(message : IpcMessage):Void {
		switch ( message.address.type ) {
			case TMain:
				_sendToMain( message );

			case TBrowserWindow( wid ):
				var window = BrowserWindow.fromId( wid );
				if (window == null) {
					throw 'Error: Invalid window id $wid';
				}
				_sendToBrowserWindow(window, message);
		}
	}

	/**
	  * send Message to the main process
	  */
	private function _sendToMain(message : IpcMessage):Void {
		trace('message sent: #${message.id}');
		var frozenMsg:IpcFrozenMessage = message.freeze();
		var packet:IpcBusPacket = Message( frozenMsg );
		Ipc.send(IpcBus.GCN, [serialize( packet )]);
	}

	/**
	  * send Message to another window
	  */
	private function _sendToBrowserWindow(window:BrowserWindow, message:IpcMessage):Void {
		null;
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
	/**
	  * decode raw packets
	  */
	private function __incoming_raw(event:IpcEvent, values:Array<Dynamic>):Void {
		if (!values.empty()) {
			var str_data:String = string(values[0]);
			try {
				var data:Dynamic = Unserializer.run( str_data );
				if (is(data, IpcBusPacket)) {
					__incoming_packet(event, cast(data, IpcBusPacket));
				}
			}
			catch(error : Dynamic) {
				return ;
			}
		}
	}

	/**
	  * handle bus packets
	  */
	private function __incoming_packet(event:IpcEvent, packet:IpcBusPacket):Void {
		trace( packet );
		switch ( packet ) {
			case Message( frozenMsg ):
				var message = frozenMsg.thaw();
				deliver( message );

			default:
				return ;
		}
	}

	/**
	  * (internal) build a socket
	  */
	override function _socket(peer : IpcAddress):IpcSocket {
		return new IpcSocket_Renderer(this, _address( peer.id ), peer);
	}

/* === Instance Fields === */

	private var bw : BrowserWindow;
}
