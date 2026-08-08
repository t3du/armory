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

		var pos = curve.getPoint(position, splineIdx);
		pos.applymat4(curve.transform.world);
		object.transform.loc.setFrom(pos);

		f.setFrom(curve.getTangent(position, splineIdx));
		f.applyQuat(curve.transform.rot);
		f.normalize();

		z.set(0, 0, 1);
		if (Math.abs(f.dot(z)) > 0.9999) {
			z.set(0, 1, 0);
		}

		r.crossvecs(f, z).normalize();
		u.crossvecs(r, f).normalize();

		switch (forwardAxis) {
			case "X":
				vx.setFrom(f);
				vy.set(-r.x, -r.y, -r.z);
				vz.setFrom(u);
			case "-X":
				vx.set(-f.x, -f.y, -f.z);
				vy.setFrom(r);
				vz.setFrom(u);
			case "Y":
				vx.setFrom(r);
				vy.setFrom(f);
				vz.setFrom(u);
			case "-Y":
				vx.set(-r.x, -r.y, -r.z);
				vy.set(-f.x, -f.y, -f.z);
				vz.setFrom(u);
			case "Z":
				vx.setFrom(r);
				vy.set(-u.x, -u.y, -u.z);
				vz.setFrom(f);
			case "-Z":
				vx.setFrom(r);
				vy.setFrom(u);
				vz.set(-f.x, -f.y, -f.z);
		}

		m._00 = vx.x; m._01 = vx.y; m._02 = vx.z;
		m._10 = vy.x; m._11 = vy.y; m._12 = vy.z;
		m._20 = vz.x; m._21 = vz.y; m._22 = vz.z;

		q.fromRotationMat(m);
		object.transform.rot.setFrom(q);

		object.transform.buildMatrix();

		runOutput(0);
	}
}