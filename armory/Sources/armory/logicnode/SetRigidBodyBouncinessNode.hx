package armory.logicnode;

import iron.object.Object;
import armory.trait.physics.RigidBody;

class SetRigidBodyBouncinessNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var object: Object = inputs[1].get();
		var bounciness: Float = inputs[2].get();

		if (object == null){ runOutput(0); return; }

		#if arm_physics
		var rb = object.getTrait(RigidBody);
		if (rb != null && rb.body != null) {
			rb.restitution = bounciness;
			rb.body.setRestitution(bounciness);
			rb.activate();
		}
		#end

		runOutput(0);
	}
}