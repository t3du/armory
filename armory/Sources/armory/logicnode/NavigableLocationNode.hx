package armory.logicnode;

#if arm_navigation
import armory.trait.navigation.Navigation;
import armory.trait.NavMesh;
#end

import iron.object.Object;
import iron.math.Vec4;

class NavigableLocationNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);

	}

	override function get(from: Int): Dynamic {
		#if arm_navigation
			var object: Object = inputs[0].get();

			var v = new iron.math.Vec4();

			var centerLoc: Vec4 = object.transform.world.getLoc();
			var dim: Vec4 = object.transform.dim;

			var v = new Vec4(
				centerLoc.x + dim.x * 0.5 * (Math.random() * 2.0 - 1.0),
				centerLoc.y + dim.y * 0.5 * (Math.random() * 2.0 - 1.0),
				centerLoc.z + dim.z * 0.5 * (Math.random() * 2.0 - 1.0)
			);

			var activeNavMesh: NavMesh = object.getTrait(NavMesh);
		
			assert(Error, activeNavMesh != null, "No Navigation Mesh Present");
			return activeNavMesh.getClosestPoint(v);
		#end
		return null;
	}
}


