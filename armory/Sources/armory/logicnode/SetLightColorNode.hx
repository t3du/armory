package armory.logicnode;

import iron.object.LightObject;

class SetLightColorNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var light: LightObject = inputs[1].get();
		var color: iron.math.Vec4 = inputs[2].get();

		if (light == null){ runOutput(0); return; }

		light.color = color;

		runOutput(0);
	}
}
