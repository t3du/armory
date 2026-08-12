package armory.logicnode;

import iron.object.CurveObject;
import iron.math.Vec4;

class GetCurveSplineNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var curve: CurveObject = inputs[0].get();
		var index: Int = inputs[1].get();
		
		if (index > curve.splinesLength) return null;

		switch(from){
			case 0:
				var points: Array<Vec4> = [];
				var worldMat = curve.transform.world;
				for (point in curve.data.splines[index].points){
					var p = new Vec4(point.co[0], point.co[1], point.co[2]);
					p.applymat(worldMat);
					points.push(p);
				}
				return points;
			case 1:
				return curve.data.splines[index].closed;
			case 2:
				return curve.data.splines[index].resolution;
		}

		return null;
	}
}
