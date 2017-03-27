package pman.tools.mp3duration;

import tannus.sys.Path;
import tannus.ds.Promise;

import js.Lib.require;

class MP3Duration {
    private static var f:String->(Null<Dynamic>->Float->Void)->Void = {require('mp3-duration');};
    public static inline function duration(path:String, callback:Null<Dynamic>->Float->Void):Void f(path, callback);
    public static function getDuration(path : Path):Promise<Float> {
        return Promise.create({
            duration(path.toString(), function(error, duration) {
                if (error != null) {
                    throw error;
                }
                else {
                    return duration;
                }
            });
        });
    }
}
