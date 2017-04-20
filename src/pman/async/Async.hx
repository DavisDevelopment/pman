package pman.async;

@:callable
abstract Async<T> (Cb<T>->Void) from Cb<T>->Void {
    public inline function new(f : Cb<T>->Void)
        this = f;
}
