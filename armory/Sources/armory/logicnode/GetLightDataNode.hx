package armory.logicnode;

import iron.object.LightObject;
import iron.data.LightData;
import iron.math.Vec4;

class GetLightDataNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var light: LightObject = inputs[0].get();

		if (light.data == null) return null;

		return switch (from) {
			case 0:
				return LightData.typeToInt(light.data.raw.type);
			#if arm_single_point	
			case 1:
				return light.data.raw.type == "sun" ? light.data.raw.strength / 0.325 : light.data.raw.strength / 0.01;
			case 2:
				return new Vec4(light.data.raw.color[0], light.data.raw.color[1], light.data.raw.color[2]);
			#else
			case 1:
				return light.data.raw.type == "sun" ? light.data.raw.strength / 0.325 : light.strength / 0.01;
			case 2:
				return light.data.raw.type == "sun" ? new Vec4(light.data.raw.color[0], light.data.raw.color[1], light.data.raw.color[2]) : light.color;
			#end
			case 3:
				light.data.raw.cast_shadow;
			default:
				null;
		}

	}
}
