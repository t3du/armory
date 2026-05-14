package armory.logicnode;

import iron.math.Vec4;
import armory.trait.internal.Spectral;

class ColorsMixNode extends LogicNode {

	var result = new Vec4();

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var colors: Array<Vec4> = inputs[0].get();
		var factors: Array<Float> = inputs[1].get();

		if (colors == null || factors == null || colors.length == 0 || factors.length == 0) {
			return result;
		}

		result.setFrom(Spectral.mix(colors, factors));

		return result;
	}
}