package armory.logicnode;

import iron.math.Vec4;
import kha.Color;
import kha.graphics4.Graphics;
import armory.trait.internal.RenderDraw;

class DrawString3DNode extends LogicNode {

	var renderCb: Graphics->Int->Int->Void = null;
	var width: Float = 0.0;
	var height: Float = 0.0;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		if (from == 0)
			if (renderCb == null)
				renderCb = RenderDraw.notifyOnRender(draw);
		else
			if (renderCb != null) {
				RenderDraw.removeOnRender(renderCb);
				renderCb = null;
			}
		runOutput(0);
	}

	function draw(rd: RenderDraw) {
		var color: Vec4 = inputs[3].get();
		var res = rd.text(inputs[2].get(), Color.fromFloats(color.x, color.y, color.z, color.w), inputs[4].get(), inputs[5].get(), inputs[6].get(),
			 inputs[7].get(), inputs[8].get(), inputs[9].get());
		width = res.width;
		height = res.height;
	}

	override function get(from: Int): Dynamic {
		return from == 1 ? width : height;
	}
}