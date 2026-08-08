package armory.logicnode;

import iron.object.CurveObject;

class SetCurveShapeKeyNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var curve: CurveObject = inputs[1].get();
		var shapeKey: String = inputs[2].get();
		var value: Float = inputs[3].get();

		if (curve == null){ runOutput(0); return; }
		curve.setShapeKey(shapeKey, value);

		runOutput(0);
	}
}