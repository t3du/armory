package armory.logicnode;

import iron.object.Object;
import iron.math.Vec4;
#if arm_physics
import armory.trait.physics.RigidBody;
#end

class SetRigidBodyGravityNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var object: Object = inputs[1].get();
		var gravity: Vec4 = inputs[2].get();
		if (object == null){ runOutput(0); return; }

		#if arm_physics
		var body = object.getTrait(RigidBody);
		if (body != null) {
			body.setGravity(gravity);
		}
		#end

		runOutput(0);
	}
}
