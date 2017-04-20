package pman.async;

@:callable
abstract VoidCb (?Dynamic->Void) from ?Dynamic->Void {
    public inline function new(f : ?Dynamic->Void):Void {
        this = f;
    }

    @:to
    public inline function void():Void->Void return f.bind(null);
    @:to
    public inline function raise():Dynamic->Void return untyped f.bind(_);
    
    public var f(get, never):?Dynamic->Void;
    private inline function get_f():?Dynamic->Void return this;
}
