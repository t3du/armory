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
		else {
			var resolution: Int = Std.int(Math.max(inputs[2].get(), 1));
			for (index in 0...curve.splinesLength)
				curve.data.splines[index].resolution = resolution;
		}

		runOutput(0);
	}
}