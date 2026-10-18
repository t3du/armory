package armory.logicnode;

import kha.Color;
import kha.graphics4.Graphics;
import armory.trait.internal.RenderDraw;

class DrawLines3DNode extends LogicNode {

	var renderCb: Graphics->Int->Int->Void = null;

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
		var arr: Array<Dynamic> = inputs[2].get();
		if (arr == null) return;
		for (i in 0...arr.length) {
			var seg: Array<Dynamic> = arr[i];
			rd.linev(seg[0], seg[1], Color.fromFloats(seg[2].x, seg[2].y, seg[2].z, seg[2].w), seg[3]);
		}
	}
}