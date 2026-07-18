package armory.logicnode;

#if arm_navigation
import armory.trait.navigation.Navigation;
import armory.trait.NavMesh;
#end

import iron.object.Object;
import iron.math.Vec4;

class AroundNavigableLocationNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);

	}

	override function get(from: Int): Dynamic {
		#if arm_navigation
			var activeNavMesh: NavMesh = Navigation.active.navMeshes.get(inputs[0].get());
			var position: Vec4 = inputs[1].get();
			var radius: Float = inputs[2].get();
		
			assert(Error, activeNavMesh != null, "No Navigation Mesh Present");
			return activeNavMesh.getRandomPointAround(position, radius);
		#end
		return null;
	}
}


