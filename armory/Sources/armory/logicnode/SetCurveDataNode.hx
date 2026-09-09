package armory.logicnode;

import iron.object.CurveObject;
import armory.trait.internal.RenderDraw;

class SetCurveDataNode extends LogicNode {
	public var property0: String;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var curve: CurveObject = inputs[1].get();

		if (property0 == "Equidistant Samples") 
			curve.equidistantSamples = inputs[2].get();
		else if (property0 == "Resolution"){
			var resolution: Int = Std.int(Math.max(inputs[2].get(), 1));
			for (index in 0...curve.splinesLength)
				curve.data.splines[index].resolution = resolution;
		} else if (property0 == "Strength"){
			curve.data.strength = inputs[2].get();
			curve.draw();
		} else if (property0 == "Color"){
			var colorInput = inputs[2].get();
			curve.data.color[0] = colorInput.x;
			curve.data.color[1] = colorInput.y;
			curve.data.color[2] = colorInput.z;
			curve.data.color[3] = colorInput.w;
			curve.draw();
		} else {
			if (inputs[2].get())
				curve.draw();
			else
				@:privateAccess if (curve.renderCb != null){
					RenderDraw.removeOnRender(curve.renderCb);
					curve.renderCb = null;
				}
		}

		runOutput(0);
	}
}