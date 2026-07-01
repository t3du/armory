package armory.logicnode;

import iron.math.Vec4;

class ColorMixNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var c1: Vec4 = inputs[0].get();
		var c2: Vec4 = inputs[1].get();
		var factor: Float = inputs[2].get();
		
		return armory.trait.internal.Spectral.mix([c1, c2], [1.0 - factor, factor]);
	}
}
