package armory.logicnode;

import iron.object.Object;
import armory.trait.physics.RigidBody;

class OnContactArrayNode extends LogicNode {

	public var property0: String;
	var lastContact = false;
	var contactObjects: Array<Object> = [];

	public function new(tree: LogicTree) {
		super(tree);

		tree.notifyOnFixedUpdate(fixedUpdate);
	}

	function fixedUpdate() {
		var object1: Object = inputs[0].get();
		var objects: Array<Object> = inputs[1].get();

		if (object1 == null) object1 = tree.object;
		if (objects == null) return;

		var currentContacts: Array<Object> = [];

#if arm_physics
		var physics = armory.trait.physics.PhysicsWorld.active;
		var rb1 = object1.getTrait(RigidBody);
		var rbs = physics.getContacts(rb1);
		if (rb1 != null && rbs != null) {
			for (object2 in objects) {
				var rb2 = object2.getTrait(RigidBody);
				for (rb in rbs) {
					if (rb == rb2) {
						currentContacts.push(object2);
						break;
					}
				}
			}
		}
#end

		var contact = currentContacts.length > 0;
		var b = false;
		switch (property0) {
		case "begin":
			b = contact && !lastContact;
		case "overlap":
			b = contact;
		case "end":
			b = !contact && lastContact;
		}

		lastContact = contact;
		contactObjects = currentContacts;

		if (b) runOutput(0);
	}

	override function get(from: Int): Dynamic {
		if (from == 1) return contactObjects;
		return contactObjects.length > 0 ? contactObjects[0] : null;
	}
}
