package armory.logicnode;

import iron.object.CameraObject;

class SetCameraProjectionNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var camera: CameraObject = inputs[1].get();
		var w: Int = inputs[2].get();
		var h: Int = inputs[3].get();

		if (camera == null) return;

		camera.buildProjection(w / h);

		runOutput(0);
	}
}
