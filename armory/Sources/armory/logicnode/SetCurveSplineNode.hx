package armory.logicnode;

import iron.object.CurveObject;

class SetCurveSplineNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var curve: CurveObject = inputs[1].get();
		var index: Int = inputs[2].get();

		if (index > curve.splinesLength){ runOutput(0); return; }

		curve.data.splines[index].closed = inputs[3].get();
		curve.data.splines[index].resolution = inputs[4].get();

		runOutput(0);
	}
}