package pman.events;

import tannus.io.Signal;
import tannus.io.Signal2;
import tannus.io.VoidSignal;
import tannus.ds.tuples.Tup2;

import tannus.async.VoidPromise;
import tannus.async.VoidCb;

import haxe.extern.EitherType;
import haxe.Constraints.Function;

import edis.Globals.defer;

using Slambda;
using tannus.FunctionTools;
using tannus.ds.AnonTools;
using tannus.ds.ArrayTools;

class EventEmitter {
    /* Constructor Function */
    public function new():Void {
        _sigs = new Map();
    }

/* === Instance Methods === */

    function addSignal<T:Sig>(name:String, ?signal:T):EventEmitter {
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

    function removeSignal(name: String):Bool {
        var entry = _getEntry( name );
        if (entry == null)
            return false;
        else {
            switch entry {
                case Zero(s): s.clear();

                case One(s):
                    s.clear();

                case Two(s):
                    s.clear();

                case _:
                    throw 'Error: Invalid signal type';
            }
            return _sigs.remove( name );
        }
    }

    inline function hasSignal(name: String):Bool {
        return _sigs.exists( name );
    }

    inline function _getEntry(name: String):Null<EventEntry> {
        return _sigs[name];
    }

    inline function _sig(name: String):Null<EventEntry> {
        if (__checkEvents && !_sigs.exists( name )) {
            throw 'Error: Event "$name" must be declared first';
        }
        else if (!_sigs.exists( name )) {
            addSignal(name, new Signal2());
        }

        return _getEntry( name );
    }

    private function _addEventListener<F:Function>(name:String, handler:F, once:Bool=false):Void {
        switch (_sig( name )) {
            case null:
                return ;

            case Zero(s):
                (once ? s.once : s.on)(untyped handler);

            case One(s):
                s.listen(untyped handler, once);

            case Two(s):
                s.listen(untyped handler, once);
        }
    }

    inline function _triggerEvent<A, B>(name:String, ?a:A, ?b:B):Void {
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

    /**
      defer the 'dispatch'ing of [name] to the next execution stack to ensure asyncronicity
      NOTE: aggregates events scheduled on the same stack to one callback for the next stack,
      and then empties the dispatch 'roster' at the end of each cycle. The reason for this 
      design is to allow for scheduled dispatches to be combined into one where possible/desired
      
      [FIXME?]
        haven't tested extensively yet, but this whole algorithm just *feels* dirty, like there's a lot more
        being done here than needs to be. Need to revisit this later and see if it can't be optimized
     **/
    public function scheduleDispatch<A,B>(name:String, ?a:A, ?b:B, combine:Bool=false, ?combinator:?A->?B->?A->?B->Null<Tup2<Null<A>,Null<B>>>):VoidPromise {
        _schedule_();

        /* create VoidPromise so that callbacks can be used/assigned without needing to be provided as a function argument */
        return new VoidPromise(function(complete, fail) {
            /* schedule the dispatch itself, also getting the index at which it was inserted */
            var i = _scheduled_.push({
                event: name,
                params: [a, b],
                callback: (function(?error) {
                    if (error != null)
                        return fail( error );
                    else
                        return complete();
                })
            });

            /* perform computations for combining "like" dispatches */
            if (combine && combinator != null) {
                var cur = _scheduled_[--i];
                if (i > 0) {
                    var rem = [];
                    for (j in 0...i) {
                        if (_scheduled_[j].event == cur.event) {
                            var rt = [_scheduled_[j].params, cur.params].with(
                                [l, r],
                                combinator(l[0], l[1], r[0], r[1])
                            );
                            if (rt != null) {
                                rem.push(_scheduled_[j]);
                                cur.params = [rt._0, rt._1];
                            }
                        }
                    }

                    /* removed the flagged dispatches from the schedule */
                    for (dd in rem) {
                        _scheduled_.remove( dd );
                    }
                }
            }
        });
    }

    function _schedule_() {
        if (_scheduled_ == null) {
            _scheduled_ = [];

            defer(function() {
                _exec_deferred_();

                _scheduled_ = null;
            });
        }
    }

    function _exec_deferred_() {
        for (dd in _scheduled_) {
            try {
                dispatch(dd.event, dd.params[0], dd.params[1]);
                dd.callback();
            }
            catch (error: Dynamic) {
                return dd.callback( error );
            }
        }
    }

/* === Instance Fields === */

    var _sigs: Map<String, EventEntry>;
    var __checkEvents: Bool = true;
    var _scheduled_: Array<DeferredDispatch>;
}

typedef Sig = EitherType<VoidSignal, EitherType<Signal<Dynamic>, Signal2<Dynamic, Dynamic>>>;
typedef DeferredDispatch = {
    var event: String;
    var params: Array<Dynamic>;
    var callback: VoidCb;
};

enum EventEntry {
    Zero(signal: VoidSignal);
    One<T>(signal: Signal<T>);
    Two<A, B>(signal: Signal2<A, B>);
}
