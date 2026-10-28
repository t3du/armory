package armory.logicnode;

import iron.math.Vec4;
import iron.math.Quat;
import kha.Color;
import kha.graphics4.Graphics;
import armory.trait.internal.RenderDraw;

class DrawStyledString3DNode extends LogicNode {

	var renderCb: Graphics->Int->Int->Void = null;
	var width: Float = 0.0;
	var height: Float = 0.0;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		if (from == 0) {
			if (renderCb == null) renderCb = RenderDraw.notifyOnRender(draw);
		}
		else if (renderCb != null) {
			RenderDraw.removeOnRender(renderCb);
			renderCb = null;
		}
		runOutput(0);
	}

	function draw(rd: RenderDraw) {
		var fillColor: Vec4 = inputs[5].get();
		var extrudeColor: Vec4 = inputs[11].get();
		var outlineColor: Vec4 = inputs[13].get();
		var result = rd.styledText(
			inputs[3].get(),
			fillColor != null ? Color.fromFloats(fillColor.x, fillColor.y, fillColor.z, fillColor.w) : Color.White,
			inputs[14].get(),
			inputs[7].get(),
			inputs[8].get(),
			inputs[9].get(),
			inputs[10].get(),
			inputs[2].get(),
			inputs[15].get(),
			inputs[12].get(),
			extrudeColor != null ? Color.fromFloats(extrudeColor.x, extrudeColor.y, extrudeColor.z, extrudeColor.w) : Color.White,
			outlineColor != null ? Color.fromFloats(outlineColor.x, outlineColor.y, outlineColor.z, outlineColor.w) : Color.Black,
			inputs[4].get(),
			inputs[6].get()
		);
		width = result.width;
		height = result.height;
	}

	override function get(from: Int): Dynamic {
		return from == 1 ? width : height;
	}
}
