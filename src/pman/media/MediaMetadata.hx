package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.ds.tuples.*;

import pman.core.*;
import pman.display.media.*;
import pman.edb.*;
import pman.edb.MediaStore;
import pman.bg.media.MediaType;
import pman.bg.media.MediaSource;

import haxe.Serializer;
import haxe.Unserializer;

import electron.Tools.defer;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;

typedef MediaMetadata = pman.bg.media.MediaMetadata;
