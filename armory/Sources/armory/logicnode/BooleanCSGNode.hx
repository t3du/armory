package armory.logicnode;

import armory.object.BooleanCSGExtension;
import iron.object.Object;

class BooleanCSGNode extends LogicNode {

	var result: Object;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		result = null;
		var a: Object = inputs[1].get();
		var b: Object = inputs[2].get();
		result = BooleanCSGExtension.createResult(a, b, inputs[3].get());
		if (result != null && inputs[4].get()) {
			a.remove();
			b.remove();
		}
		runOutput(0);
	}

	override function get(from: Int): Dynamic {
		return result;
	}
}
