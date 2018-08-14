package pman.search;

import pman.media.*;
import pman.bg.media.MediaSource;
import pman.search.QuickOpenItem;

class QoSearchEngine extends SearchEngine<QuickOpenItem> {
    override function getValues(item : QuickOpenItem):Array<String> {
        switch ( item ) {
            case QOMedia( src ):
                switch ( src ) {
                    case MSLocalPath( path ):
                        return path.pieces;
                    case MSUrl( url ):
                        return [url];
                }

            case QOPlaylist( name ):
                return [name];
        }
    }
}
