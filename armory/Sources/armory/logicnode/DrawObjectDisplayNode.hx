package armory.logicnode;

import iron.object.Object;
import iron.math.Vec4;
import kha.Color;
import kha.graphics4.Graphics;
import armory.trait.internal.RenderDraw;

class DrawObjectDisplayNode extends LogicNode {

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
		var object: Object = inputs[2].get();
		var color: Vec4 = inputs[4].get();
		switch(inputs[3].get()){
			case 0:
				rd.color = Color.fromFloats(color.x, color.y, color.z, color.w);
				rd.strength = inputs[5].get();
				rd.bounds(object.transform);
			case 1:
				rd.wireframe(cast object, Color.fromFloats(color.x, color.y, color.z, color.w), inputs[5].get());
			case 2:
				rd.outline(cast object, Color.fromFloats(color.x, color.y, color.z, color.w), inputs[5].get());
		}
	}
}