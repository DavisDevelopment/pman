package pman.bg.media;

import tannus.media.Duration;
import tannus.math.Time;

import pman.bg.media.Actor;
import pman.bg.media.Mark;
import pman.bg.media.Tag;
import pman.bg.media.Dimensions;

enum MediaAttrExtractor<T> {
    MAEActors() : Mae<Array<Actors>>;
    MAEMarks() : Mae<Array<Mark>>;
    MAETags() : Mae<Array<Tag>>;
    MAEViews() : Mae<Int>;
    MAETitle() : Mae<String>;
    MAEDuration() : Mae<Float>;
    MAEDurationTime() : Mae<Time>;
    MAEStarred(): Mae<Bool>;
    MAERating(): Mae<Float>;
    MAEContentRating(): Mae<String>;
    MAEChannel(): Mae<String>;
    MAEDescription(): Mae<String>;
    MAEAttrs(): Mae<Dict<String, Dynamic>>;
    MAEMeta(): Mae<MediaMetadata>;
    MAEMimeType(): Mae<String>;
    MAEDimensions(): Mae<Dimensions>;

    MAELambda<Data>(extract: (data:Data)->T): Mae<T>;
}

private typedef Mae<T> = MediaAttrExtractor<T>;
