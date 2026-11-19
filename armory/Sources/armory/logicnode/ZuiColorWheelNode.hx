package armory.logicnode;

import iron.math.Vec4;
import kha.Color;

#if arm_ui
import zui.Zui;
import zui.Zui.Handle;
import zui.Ext;
#end

class ZuiColorWheelNode extends LogicNode {
	#if arm_ui
	var handle: Handle;
	var color = new Vec4();
	#end

	public function new(tree: LogicTree) {
		super(tree);
	}

	#if arm_ui
	override function run(from: Int) {
		var ui = Zui.current;
		if (ui == null) return;

		if (handle == null) {
			var initial: Vec4 = inputs[1].get();
			handle = new Handle({color: Color.fromFloats(initial.x, initial.y, initial.z, initial.w)});
		}
		var previousColor = handle.color;
		Ext.colorWheel(ui, handle, inputs[2].get(), null, null, inputs[3].get());
		color.set(handle.color.R, handle.color.G, handle.color.B, handle.color.A);
		if (handle.color != previousColor) runOutput(0);
		runOutput(1);
	}

	override function get(from: Int): Dynamic {
		return color;
	}
	#end
}
