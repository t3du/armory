package armory.logicnode;

import iron.object.CurveObject;

class SetCurveDataNode extends LogicNode {
	public var property0: String;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var curve: CurveObject = inputs[1].get();

		if (property0 == "Equidistant Samples") 
			curve.equidistantSamples = inputs[2].get();
		else if (property0 == "Strength")
			curve.data.strength = inputs[2].get();
		else if (property0 == "Color")
			curve.data.color = inputs[2].get();
		else
			curve.updateMesh(inputs[2].get(), inputs[3].get(), inputs[4].get(), inputs[5].get(), inputs[6].get());

		runOutput(0);
	}
}