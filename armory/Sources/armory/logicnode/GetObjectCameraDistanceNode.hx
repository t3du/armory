package armory.logicnode;

import iron.object.MeshObject;

class GetObjectCameraDistanceNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var mo: MeshObject = cast inputs[0].get();

		if (mo == null) return null;

		var cameraDistance = mo.cameraDistance;

		if (cameraDistance == null){
			var cam = iron.Scene.active.camera;
			var object = inputs[0].get();
			cameraDistance = 
				iron.math.Vec4.distancef(cam.transform.worldx(), cam.transform.worldy(), cam.transform.worldz(), 
				object.transform.worldx(), object.transform.worldy(), object.transform.worldz());
		}

		return cameraDistance;

	}
}
