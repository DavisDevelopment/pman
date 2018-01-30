package pman.format.xspf;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.*;

import pman.bg.media.*;
import pman.format.xspf.Data;

#if renderer_process
import pman.media.Playlist;
import pman.media.Track;
#end

import Xml;

import tannus.math.TMath.*;
import Slambda.fn;

using DateTools;
using StringTools;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.ds.StringUtils;
using edis.xml.XmlTools;
using pman.bg.URITools;

class Tools {
    #if renderer_process

    /**
      * convert a pman.media.Playlist object to a pman.format.xspf.Data object
      */
    public static function toXspfData(playlist: Playlist):Data {
        var data:Data = new Data();
        //TODO copy over playlist metadata, when such a thing exists
        // copy over track information
        for (t in playlist) {
            var track = data.createTrack( t.title );
            track.addLocation( t.uri );
            if (t.data != null) {
                var d = t.data;
                if (d.meta != null && d.meta.duration != null) {
                    track.duration = ceil( d.meta.duration );
                }
                if (d.channel != null) {
                    track.album = d.channel;
                }
            }
            data.addTrack( track );
        }
        return data;
    }

    #end
}
