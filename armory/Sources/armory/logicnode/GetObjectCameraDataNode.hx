package armory.logicnode;

import iron.object.MeshObject;
import iron.Scene;

class GetObjectCameraDataNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var mo: MeshObject = cast inputs[0].get();

		if (mo == null) return null;

		if ((from == 0 && mo.cameraDistance == null) || (from == 1 && mo.screenSize == 0)) {
			var cam = Scene.active.camera;
			mo.computeCameraDistance(cam.transform.worldx(), cam.transform.worldy(), cam.transform.worldz());
			if (from == 1) {
				mo.computeScreenSize(cam);
			}
		}

		return from == 0 ? mo.cameraDistance : mo.screenSize;
	}
}