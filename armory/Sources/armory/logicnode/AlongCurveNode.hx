package armory.logicnode;

import iron.object.Object;
import iron.object.CurveObject;
import iron.math.Vec4;
import iron.math.Quat;
import iron.math.Mat4;

class AlongCurveNode extends LogicNode {

	var q = new Quat();
	var m = Mat4.identity();
	var f = new Vec4();
	var r = new Vec4();
	var u = new Vec4();
	var z = new Vec4();
	var vx = new Vec4();
	var vy = new Vec4();
	var vz = new Vec4();

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var object: Object = inputs[1].get();
		var curve: CurveObject = inputs[2].get();
		var splineIdx: Int = inputs[3].get();
		var forwardAxis: String = inputs[4].get();
		var position: Float = inputs[5].get();

		curve.follow(object, position, splineIdx, forwardAxis);

		runOutput(0);
	}
}