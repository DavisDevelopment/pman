package pman.core.history;

import pman.media.*;
import pman.display.media.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;

/**
  * Enum of types of items that can exist in the player's history
  */
enum PlayerHistoryItem {
    Media(item : PlayerHistoryMediaItem);
}

/**
  * enum of types of media-actions
  */
enum PlayerHistoryMediaItem {
    LoadTrack(track : Track);
}
