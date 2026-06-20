package armory.logicnode;

import iron.data.SceneFormat.TSceneFormat;
import iron.data.Data;
import iron.object.Object;
import iron.math.Mat4;
import armory.trait.physics.RigidBody;

class SpawnObjectByNameNode extends LogicNode {

	var object: Object;

	/** Scene from which to take the object **/
	public var property0: Null<String>;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var objectName = inputs[1].get();
		if (objectName == null){ runOutput(0); return; }

		var sceneName = property0;
		#if arm_json
		sceneName += ".json";
		#elseif arm_compress
		sceneName += ".lz4";
		#end

		var m: Mat4 = inputs[2].get();
		var matrix: Mat4 = m != null ? m.clone() : null;
		var spawnChildren: Bool = inputs[3].get();

		Data.getSceneRaw(sceneName, (rawScene: TSceneFormat) -> {

			//Check if object with given name present in the specified scene
			var objPresent: Bool = false;

			for (o in rawScene.objects) {
				if (o.name == objectName) {
					objPresent = true;
					break;
				}
			}
			if (! objPresent){ runOutput(0); return; }

			//Spawn object if present
			iron.Scene.active.spawnObject(objectName, null, function(o: Object) {
				object = o;
				if (matrix != null) {
					object.transform.setMatrix(matrix);
					#if arm_physics
					var rigidBody = object.getTrait(RigidBody);
					if (rigidBody != null) {
						object.transform.buildMatrix();
						rigidBody.syncTransform();
					}
					#end
				}
				runOutput(0);
			}, spawnChildren, rawScene);

		});
	}

	override function get(from: Int): Dynamic {
		return object;
	}
}