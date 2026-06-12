package armory.logicnode;

import iron.object.MeshObject;
import iron.data.MaterialData;

class SetMaterialSlotNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var object: MeshObject = inputs[1].get();
		var mat: MaterialData = inputs[2].get();
		var slot: Int = inputs[3].get();

		if (object == null){ runOutput(0); return; }
		if (slot >= object.materials.length){ runOutput(0); return; }

		object.materials[slot] = mat;

		runOutput(0);
	}
}
