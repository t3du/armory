package armory.logicnode;

import armory.object.VoronoiFractureExtension;
import iron.object.Object;
import iron.data.MaterialData;
import iron.math.Vec4;

class VoronoiFractureNode extends LogicNode {

	var fragments: Array<Object> = [];

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {

		var object: Object = inputs[1].get();
		if (object == null) { runOutput(0);	return;	}

		var numPoints: Int = inputs[2].get();
		var seed: Int = inputs[3].get();
		var distribution: Int = inputs[4].get();

		var impactPoint: Vec4 = inputs[5].get();
		var impactRadius: Float = inputs[6].get();

		var customPoints: Array<Vec4> = inputs[7].get();

		var interiorMaterial: MaterialData = inputs[8].get();

		var margin: Float = inputs[9].get();
		var separateLooseParts: Bool = inputs[10].get();

		fragments = VoronoiFractureExtension.createResult(
			object,
			numPoints,
			seed,
			distribution,
			impactPoint,
			impactRadius,
			interiorMaterial,
			margin,
			separateLooseParts,
			customPoints
		);

		if (inputs[11].get() && fragments.length > 0) object.remove();

		runOutput(0);
	}

	override function get(from: Int): Dynamic {
		return fragments;
	}
}