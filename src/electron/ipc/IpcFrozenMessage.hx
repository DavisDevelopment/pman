package electron.ipc;

import tannus.io.*;
import tannus.ds.*;

import haxe.Serializer;
import haxe.Unserializer;

import Std.*;
import tannus.math.TMath.*;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;

class IpcFrozenMessage {
	/* Constructor Function */
	public function new(type:IpcMessageType, id:String, channel:String, data:String, sender:IpcAddress, address:IpcAddress):Void {
		this.id = id;
		this.type = type;
		this.channel = channel;
		this.data = data;
		this.sender = sender;
		this.address = address;
	}

/* === Instance Methods === */

	/**
	  * create and return a deep copy of [this] message
	  */
	public inline function clone():IpcFrozenMessage {
		return new IpcFrozenMessage(
			IpcMessageType.createByIndex(type.getIndex(), type.getParameters().copy()),
			id,
			channel,
			data,
			sender.clone(),
			address.clone()
		);
	}

	/**
	  * convert [this] into a IpcMessage instance
	  */
	public function thaw():IpcMessage {
		var cookedData:Dynamic = Unserializer.run( data );
		var message:IpcMessage = new IpcMessage(
			IpcMessageType.createByIndex(type.getIndex(), type.getParameters().copy()),
			channel,
			cookedData,
			sender.clone(),
			address.clone()
		);
		message.id = id;
		return message;
	}

/* === Instance Fields === */

	public var type : IpcMessageType;
	public var channel : String;
	public var id : String;
	public var data : String;
	public var sender : IpcAddress;
	public var address : IpcAddress;
}
