package pman.events;

import tannus.ds.AnonTools;

class ModSensitiveEvent extends Event {
    public function new() {
        super();

        modKeys = [false, false, false, false];
    }

    public var altKey(get, set): Bool;
    private inline function get_altKey() return modKeys[0];
    private inline function set_altKey(v) return modKeys[0] = v;

    public var ctrlKey(get, set): Bool;
    private inline function get_ctrlKey() return modKeys[1];
    private inline function set_ctrlKey(v) return modKeys[1] = v;

    public var metaKey(get, set): Bool;
    private inline function get_metaKey() return modKeys[2];
    private inline function set_metaKey(v) return modKeys[2] = v;

    public var shiftKey(get, set): Bool;
    private inline function get_shiftKey() return modKeys[3];
    private inline function set_shiftKey(v) return modKeys[3] = v;

    public var noMods(get, never):Bool;
    private inline function get_noMods() return !(altKey||ctrlKey||metaKey||shiftKey);

    public var ctrlOrMeta(get, never):Bool;
    private inline function get_ctrlOrMeta() return (ctrlKey || metaKey);

    // alt, ctrl, meta, shift
    public var modKeys(default, null):Array<Bool>;
}
