package armory.logicnode;

import iron.object.LightObject;
import iron.math.Vec4;

class SetLightColorNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var light: LightObject = inputs[1].get();
		var color: Vec4 = inputs[2].get();

		if (light == null){ runOutput(0); return; }

		#if arm_single_point
		light.data.raw.color[0] = color.x;
		light.data.raw.color[1] = color.y;
		light.data.raw.color[2] = color.z;
		#else
		if (light.data.raw.type == "sun"){
			light.data.raw.color[0] = color.x;
			light.data.raw.color[1] = color.y;
			light.data.raw.color[2] = color.z;
		}
		else
			light.color = color;
		#end

		runOutput(0);
	}
}
