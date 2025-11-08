package armory.logicnode;

import iron.object.Object;
import iron.object.MeshObject;
import kha.arrays.Float32Array;

class GetObjectInstancedNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic{
		var object: Object =inputs[0].get();

		if (object == null) return null;

		var geom = cast(object, MeshObject).data.geom;

		return 
		switch(from){
			case 0: geom.instanced;
			case 1: @:privateAccess geom.data.raw.instanced_type;
			case 2: geom.instanceCount;
			case 3: toArray(@:privateAccess geom.data.raw.instanced_data);
			default: null;
		}

	}

	public static function toArray(elements: Float32Array): Array<Float>{
		if (elements == null) return null;
        var len = elements.length;
        var nid: Array<Float> = []; 
        
        for (i in 0...len) {
            nid[i] = elements[i];
        }
       
        return nid;
    }
}
