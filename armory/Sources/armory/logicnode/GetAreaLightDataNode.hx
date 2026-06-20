package armory.logicnode;

import iron.object.LightObject;

class GetAreaLightDataNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var light: LightObject = inputs[0].get();

		if (light == null) return null;

		#if arm_ltc
		if (light.data.raw.type == "area")
			if (from == 0)
				return light.data.raw.size;
			else
				return light.data.raw.size_y;
		#end

		return null;

	}
}