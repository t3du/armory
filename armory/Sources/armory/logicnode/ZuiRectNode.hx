package armory.logicnode;

import kha.Color;
import iron.math.Vec4;

#if arm_ui
import zui.Zui;
#end

class ZuiRectNode extends LogicNode {
	public function new(tree: LogicTree) {
		super(tree);
	}

	#if arm_ui
	override function run(from: Int) {
		var ui = Zui.current;
		if (ui == null) return;

		var colorVec: Vec4 = inputs[1].get();
		var strength: Float = inputs[2].get();
		var filled: Bool = inputs[3].get();
		var x: Float = inputs[4].get();
		var y: Float = inputs[5].get();
		var w: Float = inputs[6].get();
		var h: Float = inputs[7].get();
		var col = Color.fromFloats(colorVec.x, colorVec.y, colorVec.z, colorVec.w);

		if (filled)
			ui.fill(x, y, w, h, col);
		else
			ui.rect(x, y, w, h, col, strength);

		runOutput(0);
	}
	#end
}