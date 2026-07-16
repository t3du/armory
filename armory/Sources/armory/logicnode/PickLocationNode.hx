package armory.logicnode;

#if arm_navigation
import armory.trait.NavMesh;
import armory.trait.navigation.Navigation;
#end

import iron.object.Object;
import iron.math.Vec4;
import iron.math.RayCaster;
import iron.Scene;

class PickLocationNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var object: Object = inputs[0].get();
		var x: Int = inputs[1].get();
		var y: Int = inputs[2].get();

		var loc = new Vec4();

		#if arm_navigation
		var navTrait: NavMesh = Navigation.active.navMeshes[0];
		var useChildren = navTrait != null && navTrait.combineImmidiateChildren;
		#end

		#if arm_physics
		var physics = armory.trait.physics.PhysicsWorld.active;
		var b = physics.pickClosest(x, y);

		var hit = false;

		var rb = object.getTrait(armory.trait.physics.RigidBody);
		if (rb != null && b == rb)
			hit = true;

		if (!hit) {
			#if arm_navigation
			if (useChildren) {
				for (child in object.children) {
					if (child.raw.type != "mesh_object") continue;

					var childRb = child.getTrait(armory.trait.physics.RigidBody);
					if (childRb != null && childRb == b) {
						hit = true;
						break;
					}
				}
			}
			#end
		}

		if (hit) {
			var p = physics.hitPointWorld;
			loc.set(p.x, p.y, p.z);
			return loc;
		}
		else
			return null;
		#end

		#if arm_navigation
		assert(Error, Navigation.active.navMeshes.length > 0, "No Navigation Mesh Present");

		loc = RayCaster.boxIntersectObject(object, x, y, Scene.active.camera);

		if (loc == null && useChildren) {
			for (child in object.children) {
				if (child.raw.type != "mesh_object") continue;

				loc = RayCaster.boxIntersectObject(child, x, y, Scene.active.camera);

				if (loc != null) break;
			}
		}

		return loc != null ? Navigation.active.navMeshes[0].getClosestPoint(loc) : null;
		#end

		return null;
	}
}