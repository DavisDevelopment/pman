package pman.events;

import tannus.io.Signal;
import tannus.io.Signal2;
import tannus.io.VoidSignal;

import haxe.extern.EitherType;
import haxe.Constraints.Function;

using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;

class EventEmitter {
    /* Constructor Function */
    public function new():Void {
        _sigs = new Map();
    }

/* === Instance Methods === */

    private function addSignal<T:Sig>(name:String, ?signal:T):EventEmitter {
        var entry:EventEntry;
        if ((signal is VoidSignal)) {
            entry = Zero(cast signal);
        }
        else if ((signal is Signal<Dynamic>)) {
            entry = One(cast signal);
        }
        else if ((signal is Signal2<Dynamic, Dynamic>)) {
            entry = Two(cast signal);
        }
        else {
            entry = null;
            throw 'Error: Invalid signal type';
        }

        _sigs[name] = entry;
        return this;
    }

    private inline function _getEntry(name: String):Null<EventEntry> {
        return _sigs[name];
    }

    private function _sig(name: String):Null<EventEntry> {
        if (__checkEvents && !_sigs.exists( name )) {
            throw 'Error: Event "$name" must be declared first';
        }
        else if (!_sigs.exists( name )) {
            addSignal(name, new Signal2());
        }

        return _getEntry( name );
    }

    private function _addEventListener<F:Function>(name:String, handler:F, once:Bool=false):Void {
        inline function _on(s: Dynamic):Function return (once ? s.once : s.on);

        switch (_sig( name )) {
            case null:
                return ;

            case Zero(s):
                _on( s )( handler );

            case One(s):
                _on(s)(cast handler);

            case Two(s):
                _on(s)(cast handler);
        }
    }

    private function _triggerEvent<A, B>(name:String, ?a:A, ?b:B):Void {
        switch (_sig( name )) {
            case null:
                //
            case Zero(s):
                s.call();

            case One(s):
                s.call(cast a);

            case Two(s):
                s.call(cast a, cast b);
        }
    }

    private function dispatch<A, B>(name:String, ?a:A, ?b:B):Void {
        _triggerEvent(name, a, b);
    }

    public function on<F:Function>(name:String, handler:F):Void {
        _addEventListener(name, handler);
    }

    public function once<F:Function>(name:String, handler:F):Void {
        _addEventListener(name, handler, true);
    }

/* === Instance Fields === */

    private var _sigs: Map<String, EventEntry>;
    private var __checkEvents: Bool = true;
}

typedef Sig = EitherType<VoidSignal, EitherType<Signal<Dynamic>, Signal2<Dynamic, Dynamic>>>;

enum EventEntry {
    Zero(signal: VoidSignal);
    One<T>(signal: Signal<T>);
    Two<A, B>(signal: Signal2<A, B>);
}
