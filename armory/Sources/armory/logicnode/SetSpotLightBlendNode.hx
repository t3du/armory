package armory.logicnode;

import iron.object.LightObject;

class SetSpotLightBlendNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var light: LightObject = inputs[1].get();
		var blend: Float = inputs[2].get();

		if (light == null){ runOutput(0); return; }

		#if arm_spot
		if (light.data.raw.type == "spot"){
			#if arm_single_point
			light.data.raw.spot_blend = blend / 10;
			#else
			light.blend = blend / 10;
			#end
		}
		#end

		runOutput(0);
	}
}
