package electron.ipc;

import tannus.io.*;
import tannus.ds.*;

import Std.*;
import tannus.math.TMath.*;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;

/**
  * enumerator representing the different types of ipc addresses
  */
enum IpcAddressType {
	// the main process
	TMain;

	// a renderer process, identified by its id
	TBrowserWindow(windowId : Int);
}
