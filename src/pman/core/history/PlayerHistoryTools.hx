package pman.core.history;

import pman.media.*;
import pman.display.media.*;

import pman.core.PlayerHistory;
import pman.core.history.PlayerHistoryItem;
import pman.core.history.PlayerHistoryItem as PHItem;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;

class PlayerHistoryTools {
    /**
      * test whether the two given items are equal to one another
      */
    public static function equals(a:PHItem, b:PHItem):Bool {
        switch ([a, b]) {
            case [Media(ma), Media(mb)]:
                switch ([ma, mb]) {
                    case [LoadTrack(x), LoadTrack(y)]:
                        return x.equals( y );

                    default:
                        return ma.equals( mb );
                }

            default:
                return a.equals( b );
        }
    }

    /**
      * test whether [a] should overwrite [b]
      */
    public static function shouldOverwrite(a:PHItem, b:PHItem):Bool {
        switch ([a, b]) {
            case [Media(ma), Media(mb)]:
                switch ([ma, mb]) {
                    case [LoadTrack(x), LoadTrack(y)]:
                        return x.equals( y );

                    default:
                        return ma.equals( mb );
                }

            default:
                return a.equals( b );
        }
    }
}
