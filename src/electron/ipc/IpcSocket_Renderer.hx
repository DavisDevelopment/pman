package electron.ipc;

import tannus.io.*;
import tannus.ds.*;

/*
import electron.ext.IpcMain.IpcMainEvent in IpcEvent;
import electron.ext.IpcMain in Ipc;
import electron.ext.BrowserWindow;
import electron.ext.WebContents;
import electron.ipc.IpcAddressType;
import electron.ipc.IpcMessageType;
import electron.ipc.IpcBusPacket;
*/

import electron.ext.Remote;
import electron.ext.BrowserWindow;
import electron.ext.WebContents;
import electron.ext.IpcRenderer in Ipc;
import electron.ext.IpcRenderer.IpcRendererEvent in IpcEvent;
import electron.ext.IpcRenderer.IpcRendererMessageSender in MsgSrc;
import electron.ipc.IpcBusPacket;
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

class IpcSocket_Renderer extends IpcSocket {
	/* Constructor Function */
	public function new(bus:IpcBus_Renderer, address:IpcAddress, peerAddress:IpcAddress):Void {
		super( address );

		this.bus = cast bus;
		this.peerAddress = peerAddress;
	}

/* === Instance Methods === */

	/**
	  * message is being delivered to [this] Socket
	  */
	override function _deliver(msg : IpcMessage):Void {
		switch ( msg.type ) {
			// standard message
			case TNormal:
				msg.reply = sendReply.bind(msg, _);
				ed.dispatch(msg.channel, msg);

			// reply to a message
			case TReply:
				trace('received reply-type message for #${msg.id}');
				var handler = awaitingReply[msg.id];
				trace( handler );
				if (handler != null) {
					handler( msg.data );
				}

			// `delete` message
			case TDestroy:
				//TODO disconnect [this] Socket from its peer, and remove it from its bus's registry
				trace('deleting IpcSocket..');
		}
	}

/* === Instance Fields === */

	private var window : BrowserWindow;
}
