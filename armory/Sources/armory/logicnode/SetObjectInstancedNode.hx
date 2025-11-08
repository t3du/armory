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
		var object: Object =inputs[1].get();
		var instanced: Bool = inputs[2].get();
		var array = inputs[3].get();
		var include: Bool = inputs[4].get();

		if (object == null) return;

		var geom = cast(object, MeshObject).data.geom;

		if (instanced != geom.instanced) geom.instanced = instanced;

		if (instanced) {
			if (array == null)
				geom.instanced = false;
			else {
				var nid = null;
				if (property0 == '1') nid = fromArray(include ? [0.0, 0.0, 0.0].concat(array) : array);
				else
				if (property0 == '2')
					nid = fromArray(include ? [0.0, 0.0, 0.0, 0.0, 0.0, 0.0].concat(array) : array);
				else
				if (property0 == '3')
					nid = fromArray(include ? [0.0, 0.0, 0.0, 1.0, 1.0, 1.0].concat(array) : array);
				else
					nid = fromArray(include ? [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0].concat(array) : array);

				@:privateAccess geom.data.raw.instanced_data = nid;

				geom.setupInstanced(nid, @:privateAccess geom.data.raw.instanced_type, Usage.StaticUsage);
			}

		}

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
