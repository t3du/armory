package armory.logicnode;

import iron.object.Object;
import armory.trait.physics.RigidBody;

class SetRigidBodyAnimatedNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var object: Object = inputs[1].get();
		var isAnimated: Bool = inputs[2].get();

		if (object == null) return;

		#if arm_physics
		var rb = object.getTrait(RigidBody);
		if (rb != null && rb.body != null) {
			var bodyColl: bullet.Bt.CollisionObject = rb.body;
			if (isAnimated) {
				bodyColl.setCollisionFlags(bodyColl.getCollisionFlags() | 2); // CF_KINEMATIC_OBJECT
				rb.animated = true;
			} else {
				bodyColl.setCollisionFlags(bodyColl.getCollisionFlags() & ~2);
				rb.animated = false;
			}
			rb.activate();
		}
		#end

		runOutput(0);
	}
}