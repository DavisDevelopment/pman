package pman.async;

import haxe.Constraints.Function;

class Task2<T> {
    public function new() {

    }

    public function run(?cb : Cb<T>):Void {
        if (cb == null) {
            cb = (function(?e, ?v:T) {
                if (e != null)
                    throw e;
                else
                    trace('result: $v');
            });
        }
        execute( cb );
    }

    private function execute(callback : Cb<T>):Void {
        callback('Error: not implemented');
    }
}
