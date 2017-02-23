package electron.ipc;

enum IpcBusPacket {
	Connect(address : IpcAddress);
	Message(message : IpcFrozenMessage);
}
