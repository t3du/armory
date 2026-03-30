package armory.logicnode;

import iron.object.Object;
import armory.trait.physics.RigidBody;

class SetRigidBodyFrictionNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var obj: Object = inputs[1].get();
		var friction: Float = inputs[2].get();
		var angFriction: Float = inputs[3].get();

		if (obj == null) return;
		var rb = obj.getTrait(RigidBody);
		if (rb != null) {
			rb.friction = friction;
			rb.angularFriction = angFriction;
			
			rb.body.setFriction(friction);
			rb.body.setRollingFriction(angFriction);
			rb.activate();
		}

		runOutput(0);
	}
}