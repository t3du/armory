package armory.logicnode;

import armory.trait.internal.CanvasScript;

class SetGlobalCanvasVisibilityNode extends LogicNode {

	var canvas: CanvasScript;

	public function new(tree:LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		#if arm_ui
			var value: Bool = inputs[1].get();
			canvas = CanvasScript.getActiveCanvas();

			canvas.notifyOnReady(() -> {
				canvas.setCanvasVisible(value);
				runOutput(0);
			});

		#end
	}
}
