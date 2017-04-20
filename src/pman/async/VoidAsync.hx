package pman.async;

@:callable
abstract VoidAsync (VoidCb->Void) from VoidCb->Void {
    public inline function new(f : VoidCb->Void)
        this = f;
}
