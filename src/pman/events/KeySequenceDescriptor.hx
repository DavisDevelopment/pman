package pman.events;

import tannus.events.Key;

using Slambda;
using tannus.FunctionTools;
using tannus.ds.IteratorTools;

class KeySequenceDescriptor {
    /* Constructor Function */
    public function new(lead:KeyboardEventDescriptor, sequence:Array<Key>) {
        this.lead = lead;
        this.sequence = sequence;
    }

/* === Instance Methods === */

    public function keys(includeLeadKey:Bool=false):Array<Key> {
        return includeLeadKey ? [lead.key].concat(sequence) : sequence;
    }

    /**
      checks a given event against [this] description of a key-event sequence
     **/
    public function test(event: KeyboardEvent):Bool {
        if (event.previousKeyboardEvent == null) {
            return (sequence.empty() && lead.test( event ));
        }
        else {
            var it = lsi(), key: Key;
            var a:Bool=false;
            while (it.hasNext() && event.previousKeyboardEvent != null) {
                key = it.next();
                if (event.key == key) {
                    a = true;
                    event = event.previousKeyboardEvent;
                }
                else {
                    return false;
                }
            }
            if (it.hasNext() || event.previousKeyboardEvent != null) {
                return false;
            }

            // well, all tests passed and the correct number of tests were administered
            return true;
        }
    }

    private function lsi(offset:Int=0, includeLeadKey:Bool=false):Iterator<Key> {
        var i:Int = (sequence.length - offset),
        a:Array<Key> = keys( includeLeadKey ),
        lii:Iterator<Int> = {hasNext: fn(--i >= 0), next: fn(i)};
        return lii.map.fn(a[_]);
    }

/* === Computed Instance Fields === */
/* === Instance Fields === */

    public var lead(default, null): KeyboardEventDescriptor;
    public var sequence(default, null): Array<Key>;
}
