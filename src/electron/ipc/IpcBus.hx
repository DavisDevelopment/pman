package electron.ipc;

import tannus.io.*;
import tannus.ds.*;

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

/**
  * 'Bus' for ipc messages
  */
class IpcBus {
	/* Constructor Function */
	public function new():Void {
		sockets = new Map();
		socketConnected = new Signal();

		__init();
	}

/* === Instance Methods === */

	// initialize [this] bus
	private function __init():Void {
		return ;
	}

	// create new Socket
	public function createSocket(id:String, ?peerType:IpcAddressType):IpcSocket {
		ni();
	}

	/**
	  * validate the given Address
	  */
	private function canConnectTo(address : IpcAddress):Bool {
		return true;
	}

	/**
	  * create and return the IpcAddress for the given id
	  */
	private inline function _address(id : String):IpcAddress {
		return new IpcAddress(id, addressType);
	}

	/**
	  * method used by Sockets attached to [this] Bus to send messages
	  */
	@:allow( electron.ipc.IpcSocket )
	private function _broadcast(message : IpcMessage):Void {
		ni();
	}

	/**
	  * (internal) create a Socket
	  */
	private function _socket(peer : IpcAddress):IpcSocket {
		ni();
	}

/* === Instance Fields === */

	public var socketConnected : Signal<IpcSocket>;

	private var addressType : IpcAddressType;
	private var sockets : Map<String, IpcSocket>;

/* === Class Methods === */

	/**
	  * get an IpcBus instance
	  */
	public static function get():IpcBus {
		if (_instance == null) {
#if main_process
			_instance = new IpcBus_Main();
#elseif renderer_process
			_instance = new IpcBus_Renderer();
#else
			_instance = new IpcBus();
#end
		}
		return _instance;
	}

/* === Class Fields === */

	private static var _instance : Null<IpcBus> = null;

	// the value used for the 'channel' argument across the entire ipc.sockets api
	public static inline var GCN:String = 'ipc::sockets';
}
