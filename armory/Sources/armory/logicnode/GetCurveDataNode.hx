package armory.logicnode;

import iron.object.CurveObject;
import iron.math.Vec4;

class GetCurveDataNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var curve: CurveObject = inputs[0].get();
		if (curve == null) return null;
		return 
			switch (from) {
				case 0: 
					curve.splinesLength;
				case 1:
					curve.equidistantSamples;
				case 2:
					curve.visible;
				case 3:
					curve.data.strength;
				case 4: 
					new Vec4(curve.data.color[0], curve.data.color[1], curve.data.color[2], curve.data.color[3]);
				case 5:
					curve.meshData;
				default:
					null;
			}
	}
}
