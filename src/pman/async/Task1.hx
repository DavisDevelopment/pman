package pman.async;

import haxe.Constraints.Function;

class Task1 {
    public function new() {

    }

    public function run(?cb : VoidCb):Void {
        if (cb == null) {
            cb = (function(?e) {
                if (e != null)
                    throw e;
            });
        }
        execute( cb );
    }

    private function execute(callback : VoidCb):Void {
        callback('Error: not implemented');
    }
}
