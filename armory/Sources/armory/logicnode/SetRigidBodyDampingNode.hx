package armory.logicnode;

import iron.object.Object;
import armory.trait.physics.RigidBody;

class SetRigidBodyDampingNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var object: Object = inputs[1].get();
		var linear: Float = inputs[2].get();
		var angular: Float = inputs[3].get();

		if (object == null) return;

		#if arm_physics
		var rb = object.getTrait(RigidBody);
		if (rb != null && rb.body != null) {
			rb.linearDamping = linear;
			rb.angularDamping = angular;
			
			rb.body.setDamping(linear, angular);
		}
		#end

		runOutput(0);
	}
}