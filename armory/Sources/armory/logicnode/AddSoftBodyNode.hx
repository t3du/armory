package armory.logicnode;

import iron.object.Object;
import armory.trait.physics.bullet.SoftBody;

class AddSoftBodyNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var obj: Object = inputs[1].get();
		var shape: Int = inputs[2].get(); // 0: Cloth, 1: Volume
		var bend: Float = inputs[3].get();
		var mass: Float = inputs[4].get();
		var margin: Float = inputs[5].get();

		if (obj == null) return;

		var sb = new SoftBody(shape, bend, mass, margin);
		obj.addTrait(sb);

		runOutput(0);
	}
}