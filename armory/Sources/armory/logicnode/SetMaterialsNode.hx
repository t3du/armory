package armory.logicnode;

import iron.object.MeshObject;
import iron.data.MaterialData;

class SetMaterialsNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var object: MeshObject = inputs[1].get();
		var mats = inputs[2].get();

		if (object == null) return;
		if (mats == null) return;

		object.materials = mats;

		runOutput(0);
	}
}
