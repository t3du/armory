package armory.logicnode;

import iron.math.Vec4;

class MathConstantsNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override public function get(index: Int): Dynamic {
		if (index == 0) return Math.NEGATIVE_INFINITY;
		else if (index == 1) return Math.POSITIVE_INFINITY;
		else return Math.PI;
	}
}