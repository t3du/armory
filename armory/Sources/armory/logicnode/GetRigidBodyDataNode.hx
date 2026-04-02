package armory.logicnode;

import iron.object.Object;
import iron.math.Vec4;
import armory.trait.physics.RigidBody;

class GetRigidBodyDataNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var object: Object = inputs[0].get();

		if (object == null) return null;

#if arm_physics
		var rb = object.getTrait(RigidBody);
		if (rb == null) return null;

		return switch (from) {
			case 0: true;
			case 1: rb.group;
			case 2: rb.mask;
			case 3: rb.animated;
			case 4: rb.staticObj;
			case 5: rb.linearDamping;
			case 6: rb.angularDamping;
			case 7: rb.friction;
			case 8: rb.angularFriction;
			case 9: rb.mass;
			case 10: (rb.body.getCollisionFlags() & 4) != 0;
			case 11: rb.restitution;
			case 12: rb.body.getGravity().length() > 0.0001;
			case 13:
				var v = rb.body.getLinearFactor();
				return new Vec4(v.x(), v.y(), v.z());
			case 14:
				var v = rb.body.getAngularFactor();
				return new Vec4(v.x(), v.y(), v.z());
			default: null;
		}
#end
		return null;
	}
}