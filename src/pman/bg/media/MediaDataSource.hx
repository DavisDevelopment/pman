package pman.bg.media;

import tannus.ds.Object;
import tannus.ds.Dict;

import pman.bg.media.MediaRow;

enum MediaDataSource {
    Empty;
    Partial(properties:Array<String>, data:MediaDataSourceState);
    Complete(row: MediaDataSourceState);
}

enum MediaDataSourceDecl {
    Empty;
    Partial(properties: Array<String>);
    Complete;
}

typedef MediaDataSourceState = {
    ?row: MediaRow,
    initial: NullableMediaDataState,
    current: NullableMediaDataState
};

typedef NullableMediaDataState = {
    >NullableRawBaseMediaData,

    ?marks: Array<Mark>,
    ?tags: Array<Tag>,
    ?actors: Array<Actor>,
    ?attrs: Dict<String, Dynamic>
};
