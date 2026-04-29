package armory.logicnode;

import iron.object.Object;
import armory.trait.physics.RigidBody;

class GetContactsNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var object: Object = inputs[0].get();

		if (object == null) return null;

#if arm_physics
		var physics = armory.trait.physics.PhysicsWorld.active;
		var rb = object.getTrait(RigidBody);
		if (rb == null) return null;
		var rbs = physics.getContacts(rb);
		var obs = [];

		if (rbs != null) for (rb in rbs) if (rb != null) obs.push(rb.object);
		return obs;
#end

		return null;
	}
}
