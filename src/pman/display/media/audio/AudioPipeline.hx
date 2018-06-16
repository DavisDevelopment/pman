package pman.display.media.audio;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.sys.*;
import tannus.async.*;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.media.MediaObject;
import gryffin.audio.*;
import gryffin.audio.AudioNode;

import pman.core.*;
import pman.media.*;
import pman.display.media.LocalMediaObjectRenderer in Lmor;
import pman.display.media.audio.AudioPipelineNode;

import Std.*;
import tannus.math.TMath.*;
import edis.Globals.*;
import pman.Globals.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.html.JSTools;
using tannus.FunctionTools;
using tannus.async.Asyncs;

/*
   class used to represent the flow of audio data through a pipeline
*/
class AudioPipeline extends MediaRendererComponent {
    /* Constructor Function */
    public function new(renderer : LocalMediaObjectRenderer<MediaObject>):Void {
        super();

        this.renderer = renderer;
        active = false;
        treeBuilders = new Array();
        nodeList = new Array();
    }

/* === Instance Methods === */

    /**
      * when [this] is attached to the MediaRenderer
      */
    override function attached(done: VoidCb):Void {
        activate( done );
    }

    /**
      * when [this] it detached from the MediaRenderer
      */
    override function detached(done: VoidCb):Void {
        trace('deactivating AudioPipeline..');
        deactivate(function(?error) {
            trace('detach complete');
            done( error );
        });
    }

    /**
      * Activate [this]
      */
    public function activate(?done : VoidCb):Void {
        if (done == null) {
            done = VoidCb.noop;
        }

        // override [done]
        done = done.wrap(function(_, ?error) {
            if (error != null) {
                _( error );
            }
            else {
                defer(() -> announceAttached());
                _();
            }
            //_( error );
        });

        if ( !active ) {
            buildit(function() {
                active = true;

                done();
            });
        }
        else {
            throw 'Error: Cannot reactivate an active AudioPipeline';
        }
    }

    /**
      * Deactivate [this]
      */
    public function deactivate(?done : VoidCb):Void {
        if (done == null) {
            done = VoidCb.noop;
        }

        done = done.wrap(function(_, ?error) {
            active = false;
            _closing = false;
            context = null;
            deallocate();
            trace('AudioPipeline deallocation');
            _( error );
        });
        trace( done );

        if (context != null) {
            context.close( done );
        }
        else {
            done();
        }
    }

    /**
      * build out the AudioNode tree
      */
    @:access( pman.display.media.LocalMediaObjectRenderer )
    public function buildTree(done : VoidCb):Void {
        var prepare = ((context != null) ? context.close : defer);

        prepare(function() {
            context = new AudioContext();
            source = context.createSource(untyped renderer.mediaObject);
            destination = context.destination;

            source.connect( destination );

            for (f in treeBuilders) {
                f( this );
            }

            defer(done.void());
        });
    }

    /**
      * rebuild the node-tree structure
      */
    public function rebuildit(done: Void->Void):Void {
        if (context == null) {
            return buildit( done );
        }

        try {
            source.disconnect();
        }
        catch (error: Dynamic) {
            null;
        }

        source = context.createSource(untyped renderer.mediaObject);
        destination = context.destination;
        srcNode = new SourceAudioPipelineNode( this );
        srcNode.init();
        destNode = new DestAudioPipelineNode( this );
        destNode.init();
        currentNode = srcNode;
        for (node in nodeList) {
            node.init();

            connectNodes(currentNode, node);
            currentNode = node;
        }
        connectNodes(currentNode, destNode);
    }

    /**
      * build out the node list
      */
    public function buildit(done: Void->Void):Void {
        //var prepare = ((context != null) ? context.close : defer);
        var mumps:Void->Void = (function() {
            return ;
        });

        function prepare(f: Void->Void) {
            if (context != null) {
                context.close( f );
            }
            else {
                call( f );
            }
        }

        mumps
        .join(function() {
            context = new AudioContext();
            
            try {
                source.disconnect();
                source = null;
            }
            catch (error: Dynamic) {
                null;
            }

            source = context.createSource(untyped renderer.mediaObject);
            destination = context.destination;

            srcNode = new SourceAudioPipelineNode( this );
            srcNode.init();

            destNode = new DestAudioPipelineNode( this );
            destNode.init();
            currentNode = srcNode;

            for (node in nodeList) {
                node.init();

                connectNodes(currentNode, node);
                currentNode = node;
            }

            connectNodes(currentNode, destNode);

            //defer( done );
            done();
        })
        .passTo( prepare );
    }

    /**
      * rebuild the tree
      */
    public function rebuildTree(done : VoidCb):Void {
        deactivate(function(?error) {
            if (error != null) {
                done( error );
            }
            else {
                activate( done );
            }
        });
    }

    /**
      * garbage-collect [thise] object
      */
    public function deallocate():Void {
        source = null;
        destination = null;
        srcNode = null;
        destNode = null;
        currentNode = null;
        treeBuilders = [];
        for (node in nodeList) {
            node.disconnect();
        }
        nodeList = [];
    }

    /**
      * create and return a new AudioPipelineNode
      */
    public inline function createNode(options: FAPDef):FunctionalAudioPipelineNode {
        return new FunctionalAudioPipelineNode(this, options);
    }

    /**
      * append the given list of nodes
      */
    public function appendNodes(nodes: Array<AudioPipelineNode>):Void {
        for (node in nodes) {
            appendNode( node );
        }
    }

    /**
      * append a node to [this] pipeline
      */
    public function appendNode(node: AudioPipelineNode):Void {
        var tmp = destNode.prevNode;
        if (tmp == null) {
            throw 'Error: No node to attach to';
        }
        else {
            dis( tmp );
        }

        connectNodes(tmp, node);
        connectNodes(node, destNode);
        currentNode = node;
    }

    /**
      * prepend a node to [this] pipeline
      */
    public function prependNode(node: AudioPipelineNode):Void {
        if (srcNode == null) {
            throw 'Error: No node to attach to';
        }

        var tmp = srcNode.nextNode;

        dis( srcNode );
        connectNodes(srcNode, node);
        if (tmp != null) {
            connectNodes(node, tmp);
        }
    }

    /**
      * connect two nodes
      */
    public inline function connectNodes(a:AudioPipelineNode, b:AudioPipelineNode):Void {
        if (!a.isInitted()) {
            a.init();
        }

        if (!b.isInitted()) {
            b.init();
        }

        a.connect( b );
        a.setNextNode( b );
    }

    private static function call(f: Void->Void):Void f();
    inline static function dis(n: AudioPipelineNode) {
        try {
            n.disconnect();
        }
        catch (e: Dynamic) {
            return ;
        }
    }

/* === Instance Fields === */

    //public var renderer : LocalMediaObjectRenderer<MediaObject>;
    public var context : AudioContext;
    public var source : AudioSource;
    public var destination : AudioDestination;
    public var srcNode: SourceAudioPipelineNode;
    public var destNode: DestAudioPipelineNode;

    public var active(default, null):Bool;

    //public var treeBuilders : Array<AudioManager->AudioPipelineNode->AudioPipelineNode>;
    public var treeBuilders: Array<AudioPipeline->Void>;

    private var nodeList: Array<AudioPipelineNode>;
    private var currentNode: Null<AudioPipelineNode> = null;
    private var _closing : Bool = false;
}

/*
   class used to represent an AudioPipelineNode that was created functionally
*/
class FunctionalAudioPipelineNode extends AudioPipelineNode {
    /* Constructor Function */
    public function new(pipeline:AudioPipeline, def:FAPDef):Void {
        super( pipeline );

        d = def;
    }

/* === Instance Methods === */

    override function connect(nextNode:AudioPipelineNode):Void {
        if (d.connect != null) {
            d.connect(this, nextNode);
        }
        else {
            super.connect( nextNode );
        }
    }

    override function init():Void {
        if (d.init != null) {
            d.init( this );
        }
        super.init();
    }

/* === Instance Fields === */

    public var d:FAPDef;
}

typedef FAPDef = {
    ?connect: FunctionalAudioPipelineNode->AudioPipelineNode->Void,
    ?init: FunctionalAudioPipelineNode->Void
};

class SourceAudioPipelineNode extends AudioPipelineNode {
    override function init():Void {
        setNode(null, cast pipeline.source);
    }
}

class DestAudioPipelineNode extends AudioPipelineNode {
    override function init():Void {
        setNode(cast pipeline.destination);
    }
}

typedef Fapn = FunctionalAudioPipelineNode;
