package armory.logicnode;

#if arm_navigation
import armory.trait.navigation.Navigation;
#end

import iron.object.Object;
import iron.math.Vec4;

class PickLocationNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var object: Object = inputs[0].get();
		var x: Int = inputs[1].get();
		var y: Int = inputs[2].get();

		var loc = new Vec4();

		#if arm_physics
		var physics = armory.trait.physics.PhysicsWorld.active;
		var b = physics.pickClosest(x, y);
		var rb = object.getTrait(armory.trait.physics.RigidBody);

		if (rb != null && b == rb) {
			var p = physics.hitPointWorld;
			trace(p);
			loc.set(p.x, p.y, p.z);
			return loc;
		}
		#end

		#if arm_navigation
		trace('here');
		assert(Error, Navigation.active.navMeshes.length > 0, "No Navigation Mesh Present");
		loc = iron.math.RayCaster.boxIntersectObject(object, x, y, iron.Scene.active.camera);
		return loc != null ? Navigation.active.navMeshes[0].getClosestPoint(loc) : null;
		#end
		
		return null;
	}
}
