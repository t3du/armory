package armory.logicnode;

import iron.object.LightObject;

class SetLightStrengthNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var light: LightObject = inputs[1].get();
		var strength: Float = inputs[2].get();

		if (light == null){ runOutput(0); return; }

		#if arm_single_point
		light.data.raw.strength = light.data.raw.type == "sun" ? strength * 0.325 : strength * 0.01;
		#else 
		if (light.data.raw.type == "sun")
			light.data.raw.strength = strength * 0.325;
		else
			light.strength = strength * 0.01;
		#end

		runOutput(0);
	}
}
