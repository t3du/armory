package armory.logicnode;

import iron.object.Object;
import iron.object.MeshObject;
import iron.object.CameraObject;

class SetCameraRenderFilterNode extends LogicNode {

	public var property0: String;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var object: Object = inputs[1].get();
		var mo: MeshObject = cast object;
		var camera: CameraObject = inputs[2].get();
		var children: Bool = inputs[3].get();
		var recursive: Bool = inputs[4].get();
		
		assert(Error, Std.isOfType(camera, CameraObject), "Camera must be a camera object!");
		
		if (camera == null || mo == null) return;
		
		if (property0 == 'Add'){
			if (mo.cameraList == null || mo.cameraList.indexOf(camera.name) == -1){
				if (mo.cameraList == null) mo.cameraList = [];
				mo.cameraList.push(camera.name);
			}
		}
		else{
			if (mo.cameraList != null){
				mo.cameraList.remove(camera.name);
				if (mo.cameraList.length == 0)
					mo.cameraList = null;
			}
		}

		if (children) setCRFRecursive(property0, object, camera.name, recursive);

		runOutput(0);
	}

	function setCRFRecursive(property: String, object: Object, camName: String, recursive: Bool) {
		var objectChildren: Array<Object> = object.children;
		for (child in objectChildren) {
			var mo: MeshObject = cast child;
			if (property == 'Add'){
				if (mo.cameraList == null || mo.cameraList.indexOf(camName) == -1){
					if (mo.cameraList == null) mo.cameraList = [];
					mo.cameraList.push(camName);
				}
			}
			else{
				if (mo.cameraList != null){
					mo.cameraList.remove(camName);
					if (mo.cameraList.length == 0)
						mo.cameraList = null;
				}
			}
			if (recursive) setCRFRecursive(property, child, camName, recursive);
		}
	}


}
