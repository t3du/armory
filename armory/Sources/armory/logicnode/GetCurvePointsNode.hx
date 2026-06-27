package armory.logicnode;

import iron.object.CurveObject;
import iron.math.Vec4;

class GetCurvePointsNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var curve: CurveObject = inputs[0].get();
		var index: Int = inputs[1].get();
		var points: Array<Vec4> = [];

		var worldMat = curve.transform.world;

		if (index > curve.splinesLength) return null;

		if (from == 0){
			for (point in curve.data.splines[index].points){
				var p = new Vec4(point.co[0], point.co[1], point.co[2]);
				p.applymat(worldMat);
				points.push(p);
			}
			return points;
		}
		else
			return curve.data.splines[index].closed;
	}
}
