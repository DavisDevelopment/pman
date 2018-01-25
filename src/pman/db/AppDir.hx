package pman.db;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.tuples.*;
import tannus.sys.*;
import tannus.sys.FileSystem in Fs;

import electron.ext.*;
import electron.Tools.*;

#if renderer_process

import pman.core.*;
import pman.media.Playlist;
import pman.Globals.*;

#end

import pman.core.JsonData;
import pman.core.PlayerPlaybackProperties;
import pman.async.*;

import haxe.Json;
import haxe.Serializer;
import haxe.Unserializer;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

@:deprecated
typedef AppDir = pman.edb.AppDir;
