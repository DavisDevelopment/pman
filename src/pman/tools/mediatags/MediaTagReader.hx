package pman.tools.mediatags;

import tannus.ds.Promise;
import tannus.node.*;

import Slambda.fn;

@:jsRequire('jsmediatags', 'Reader')
extern class MediaTagReader {
    public function new(file:String):Void;
    public function setTagsToRead(tags : Array<String>):Void;
    public function read(cbo : MediaTagReadCb):Void;
    public inline function pread():Promise<TagResults> {
        return new Promise(fn([y, n] => read({onSuccess:y,onError:n})));
    }
}

typedef MediaTagReadCb = {
    onSuccess: TagResults->Void,
    onError: Dynamic->Void
};

typedef TagResults = {
    type: String,
    tags: AudioTagInfo
};

typedef AudioTagInfo = {
    ?title: String,
    ?artist: String,
    ?album:String,
    ?year:String,
    ?comment:String,
    ?track:String,
    ?genre:String,
    ?picture: AudioPictureTag
};

typedef AudioPictureTag = {
    format: String,
    type: String,
    description: String,
    data: Array<Int>
};

typedef AudioTag = {
    id: String,
    data: Buffer
};
