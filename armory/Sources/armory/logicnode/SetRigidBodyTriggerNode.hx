package armory.logicnode;

import iron.object.Object;
import armory.trait.physics.RigidBody;

class SetRigidBodyTriggerNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var object: Object = inputs[1].get();
		var isTrigger: Bool = inputs[2].get();

		if (object == null){ runOutput(0); return; }

		#if arm_physics
		var rb = object.getTrait(RigidBody);
		if (rb != null && rb.body != null) {
			var bodyColl: bullet.Bt.CollisionObject = rb.body;
			if (isTrigger) {
				bodyColl.setCollisionFlags(bodyColl.getCollisionFlags() | 4);
			} else {
				bodyColl.setCollisionFlags(bodyColl.getCollisionFlags() & ~4);
			}
			rb.activate();
		}
		#end

		runOutput(0);
	}
}