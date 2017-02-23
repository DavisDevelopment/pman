package electron.ipc;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.Memory;

import haxe.Serializer;
import haxe.Unserializer;

import Std.*;
import tannus.math.TMath.*;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;

class IpcMessage {
	/* Constructor Function */
	public function new(type:IpcMessageType, channel:String, data:Dynamic, sender:IpcAddress, address:IpcAddress):Void {
		this.id = Memory.allocRandomId( 8 );
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
	public inline function clone():IpcMessage {
		return new IpcMessage(
			//IpcMessageType.createByIndex(type.getIndex(), type.getParameters().copy()),
			type,
			channel,
			data,
			sender.clone(),
			address.clone()
		);
	}

	/**
	  * convert [this] message to 'raw' mode
	  */
	public function freeze():IpcFrozenMessage {
		var s = new Serializer();
		s.useCache = s.useEnumIndex = true;
		s.serialize( data );
		var frozenData:String = s.toString();
		return new IpcFrozenMessage(
			//IpcMessageType.createByIndex(type.getIndex(), type.getParameters().copy()),
			type,
			id,
			channel,
			frozenData,
			sender.clone(),
			address.clone()
		);
	}

	/**
	  * send a reply to [this] Message
	  */
	public dynamic function reply(data : Dynamic):Void {
		return ;
	}

	/**
	  * get the id of the recipient socket
	  */
	public inline function getRecipientId():String {
		return address.id;
	}
	public inline function getSenderId():String return sender.id;

/* === Instance Fields === */

	public var id : String;
	public var type : IpcMessageType;
	public var channel : String;
	public var data : Dynamic;
	public var sender : IpcAddress;
	public var address : IpcAddress;
}
