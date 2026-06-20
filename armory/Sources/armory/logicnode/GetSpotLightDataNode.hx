package armory.logicnode;

import iron.object.LightObject;

class GetSpotLightDataNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var light: LightObject = inputs[0].get();

		if (light == null) return null;

		#if arm_spot
		if (light.data.raw.type == "spot"){
			#if arm_single_point
			if (from == 0)
				return Math.acos(light.data.raw.spot_size) * 2;
			else
				return light.data.raw.spot_blend * 10;
			#else
			if (from == 0)
				return Math.acos(light.size) * 2;
			else
				return light.blend * 10;

			#end
		}
		#end

		return null;

	}
}