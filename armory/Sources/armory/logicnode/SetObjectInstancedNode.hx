package armory.logicnode;

import iron.object.Object;
import iron.object.MeshObject;
import kha.arrays.Float32Array;
import kha.graphics4.Usage;

class SetObjectInstancedNode extends LogicNode {

	public var property0: String;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var meshObject: MeshObject = cast inputs[1].get();
		var array = inputs[2].get();
		var include: Bool = inputs[3].get();
		var usage: Bool = inputs[3].get();

		if (meshObject == null){ runOutput(0); return; }

		var geom = meshObject.data.geom;

		var base = [];
		if (property0 == '1') base = [0.0, 0.0, 0.0];
		else if (property0 == '2') base = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
		else if (property0 == '3') base = [0.0, 0.0, 0.0, 1.0, 1.0, 1.0];
		else base = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0];

		while (base.length < geom.instanceStride)
    		base.push(0.0);

		var nid: Float32Array = null;

		if (array != null)
			nid = fromArray(include ? base.concat(array) : array);
		else
			nid = fromArray(base);

		@:privateAccess geom.data.raw.instanced_data = nid;

		if (Std.int(nid.length / geom.instanceStride) != geom.instanceCount)
			geom.setupInstanced(nid, @:privateAccess geom.data.raw.instanced_type, usage ? Usage.DynamicUsage : Usage.StaticUsage);
		else
			geom.updateInstanced(nid);
	
		runOutput(0);
	}

	public static function fromArray(elements: Array<Float>): Float32Array {
        var len = elements.length;
        var nid = new Float32Array(len); 
        
        for (i in 0...len) {
            nid[i] = elements[i];
        }
       
        return nid;
    }
}
