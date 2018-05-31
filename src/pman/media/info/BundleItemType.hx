package pman.media.info;

import pman.bg.media.Dimensions;

enum BundleItemType {
    Thumbnail(size : Dimensions);
    Snapshot(time:Float, size:Dimensions);

    //DataFile;
}
