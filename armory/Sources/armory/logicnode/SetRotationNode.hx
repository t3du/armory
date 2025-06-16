
package armory.logicnode;

import iron.object.Object;
import iron.math.Mat4;
import iron.math.Vec4;
import iron.math.Quat;
import armory.trait.physics.RigidBody;

class SetRotationNode extends LogicNode {

	public var property0 = "Local";

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var object: Object = inputs[1].get();
		if (object == null) return;
		var _q: Quat = inputs[2].get();
		if (_q == null) return;

		final q = new Quat(_q.x, _q.y, _q.z, _q.w).normalize();

		switch (property0){
		case "Local":
			object.transform.rot.setFrom(q);
			object.transform.buildMatrix();
		case "Global":
			var newLocalRot = new Quat();
			if (object.parent != null) {
				var parentGlobalRot = new Quat();
				var tempPos = new Vec4();
				var tempScale = new Vec4();
				object.parent.transform.world.decompose(tempPos, parentGlobalRot, tempScale);
				var invParentRot = new Quat().inverse(parentGlobalRot);
				newLocalRot.multquats(invParentRot, q);
			} else {
				newLocalRot.setFrom(q);
			}
			object.transform.rot.setFrom(newLocalRot);
			object.transform.buildMatrix();
		}

		#if arm_physics
		var rigidBody = object.getTrait(RigidBody);
		if (rigidBody != null) {
			rigidBody.syncTransform();
		}
		#end
		runOutput(0);
	}
}
