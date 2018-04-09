package pman.display.media;

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

import Std.*;
import tannus.math.TMath.*;
import edis.Globals.*;
import pman.Globals.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
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

        done = done.wrap(function(_, ?error) {
            trace('AudioPipeline activate!');
            _( error );
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

        done();
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
            trace('create audio context');
            context = new AudioContext();
            trace('audio context created');
            
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
   class used to represent a 'node' in the 'audio pipeline' 
   as the name implies
*/
class AudioPipelineNode {
    /* Constructor Function */
    public function new(pipeline: AudioPipeline) {
        this.iNode = null;
        this.oNode = null;
        this.pipeline = pipeline;
        this.nextNode = null;
    }

/* === Instance Methods === */

    /**
      * connect [this] node to the next one in the pipeline
      */
    public function connect(nextNode: AudioPipelineNode):Void {
        if (numberOfOutputs == 0 || nextNode.numberOfInputs == 0) {
            throw 'Error: Data-flow between these two nodes is impossible';
        }

        if (numberOfOutputs == 1) {
            oNode.connect( nextNode.iNode );
        }
        else {
            for (i in 0...numberOfOutputs) {
                oNode.connect(nextNode.iNode, [i]);
            }
        }
    }

    /**
      * disconnect [this] Node
      */
    public function disconnect():Void {
        iNode.disconnect();
        oNode.disconnect();
    }

    /**
      * initialize [this] node
      */
    public function init():Void {
        this._initted = true;
    }

    public inline function isInitted():Bool return _initted;

    /**
      * set [this]'s node
      */
    public inline function setNode(i:Null<AudioNode<NativeAudioNode>>, ?o:Null<AudioNode<NativeAudioNode>>):Void {
        if (o == null) {
            o = i;
        }

        iNode = i;
        oNode = o;
    }

    public inline function setNextNode(node: Null<AudioPipelineNode>):Void {
        this.nextNode = node;

        if (node != null)
            node.prevNode = this;
    }

    public inline function setPrevNode(node: Null<AudioPipelineNode>):Void {
        this.prevNode = node;

        if (node != null) {
            node.nextNode = this;
        }
    }


/* === Computed Instance Fields === */

    public var numberOfInputs(get, never):Int;
    private inline function get_numberOfInputs() return (iNode != null ? iNode.numberOfInputs : 0);

    public var numberOfOutputs(get, never):Int;
    private inline function get_numberOfOutputs() return (oNode != null ? oNode.numberOfOutputs : 0);

/* === Instance Fields === */

    public var iNode: Null<AudioNode<NativeAudioNode>>;
    public var oNode: Null<AudioNode<NativeAudioNode>>;
    public var pipeline: AudioPipeline;
    public var nextNode(default, null): Null<AudioPipelineNode>;
    public var prevNode(default, null): Null<AudioPipelineNode>;

    private var _initted:Bool = false;
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

typedef NativeAudioNode = js.html.audio.AudioNode;
typedef Fapn = FunctionalAudioPipelineNode;
