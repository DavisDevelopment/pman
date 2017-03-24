package pman.ds;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.sys.FSEntry.FSEntryType;

import pman.core.*;
import pman.media.*;
import pman.display.*;
import pman.display.media.*;
import pman.db.*;
import pman.media.MediaType;

import electron.ext.FileFilter;
import electron.Tools.defer;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class OpenableFileProbe extends FileFilterProbe {
    public function new():Void {
        super();

        setFilter( FileFilter.ALL );
    }
}
