package armory.logicnode;

import iron.object.Object;
import iron.math.Vec4;

class SetDimensionNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var object: Object = inputs[1].get();
		var vec:Vec4 = inputs[2].get();

		object.raw.dimensions[0] = vec.x;
		object.raw.dimensions[1] = vec.y;
		object.raw.dimensions[2] = vec.z;

		runOutput(0);

	}
}
