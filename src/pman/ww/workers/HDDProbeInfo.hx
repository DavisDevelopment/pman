package pman.ww.workers;

import tannus.sys.*;

typedef HDDSProbeInfo = {
    paths: Array<String>,
    ?filter: String,
    ?sort: String
};

typedef HDDProbeInfo<T> = {
    paths: Array<Path>,
    ?filter: T -> Bool,
    ?sort: T->T->Int
};
