package pman.async;

@:callable
abstract Cb<T> (?Dynamic->?T->Void) from ?Dynamic->?T->Void {
    public inline function new(f : ?Dynamic->?T->Void):Void {
        this = f;
    }

    @:to
    public inline function raise():Dynamic->Void return untyped f.bind(_, null);
    
    @:to
    public inline function yield():T->Void return untyped f.bind(null, _);
    
    @:to
    public inline function toVoid():Void->Void return void();
    public inline function void(?val : T):Void->Void {
        return f.bind(null, val);
    }

    public var f(get, never):?Dynamic->?T->Void;
    private inline function get_f():?Dynamic->?T->Void return this;
}
