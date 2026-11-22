package armory.logicnode;

import kha.Color;
import iron.math.Vec4;

#if arm_ui
import zui.Zui;
import zui.Zui.Align;
#end

class ZuiTextNode extends LogicNode {
	public function new(tree: LogicTree) {
		super(tree);
	}

	#if arm_ui
	override function run(from: Int) {
		var ui = Zui.current;
		if (ui == null) return;

		var align: Align = switch (inputs[2].get()) {
			case 0: Align.Left;
			case 1: Align.Center;
			default: Align.Right;
		};

		var colorVec: Vec4 = inputs[3].get();

		if (inputs[4].get())
			ui.title(inputs[1].get(), align, Color.fromFloats(colorVec.x, colorVec.y, colorVec.z, colorVec.w));
		else
			ui.text(inputs[1].get(), align, Color.fromFloats(colorVec.x, colorVec.y, colorVec.z, colorVec.w));
		runOutput(0);
	}
	#end
}
