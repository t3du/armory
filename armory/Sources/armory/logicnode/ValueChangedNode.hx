package armory.logicnode;

import iron.math.Mat4;
import iron.math.Quat;
import iron.math.Vec4;

class ValueChangedNode extends LogicNode {

	var initialized = false;
	var initialValue: Dynamic;
	var lastValue: Dynamic;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var currentValue = inputs[1].get();

		if (!initialized) {
			initialValue = clone(currentValue);
			lastValue = clone(initialValue);
			initialized = true;
			runOutput(0);
			runOutput(2);
			return;
		}

		if (equal(currentValue, lastValue)) {
			runOutput(1);
		}
		else {
			lastValue = clone(currentValue);
			runOutput(0);
		}

		if (equal(currentValue, initialValue)) {
			runOutput(2);
		}
	}

	function clone(v: Dynamic): Dynamic {
		if (v == null) return null;
		if (Std.isOfType(v, Vec4)) return (v: Vec4).clone();
		if (Std.isOfType(v, Mat4)) return (v: Mat4).clone();
		if (Std.isOfType(v, Quat)) return new Quat().setFrom(v);
		return v;
	}

	function equal(v1: Dynamic, v2: Dynamic): Bool {
		if (v1 == v2) return true;
		if (v1 == null || v2 == null) return false;

		if (Std.isOfType(v1, Vec4) && Std.isOfType(v2, Vec4)) {
			return (v1: Vec4).equals(v2);
		}
		if (Std.isOfType(v1, Quat) && Std.isOfType(v2, Quat)) {
			return v1.x == v2.x && v1.y == v2.y && v1.z == v2.z && v1.w == v2.w;
		}
		if (Std.isOfType(v1, Mat4) && Std.isOfType(v2, Mat4)) {
			var m1: Mat4 = v1;
			var m2: Mat4 = v2;
			return m1._00 == m2._00 && m1._01 == m2._01 && m1._02 == m2._02 && m1._03 == m2._03 &&
			       m1._10 == m2._10 && m1._11 == m2._11 && m1._12 == m2._12 && m1._13 == m2._13 &&
			       m1._20 == m2._20 && m1._21 == m2._21 && m1._22 == m2._22 && m1._23 == m2._23 &&
			       m1._30 == m2._30 && m1._31 == m2._31 && m1._32 == m2._32 && m1._33 == m2._33;
		}
		return false;
	}
}
