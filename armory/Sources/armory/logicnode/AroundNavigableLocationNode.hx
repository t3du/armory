package armory.logicnode;

#if arm_navigation
import armory.trait.navigation.Navigation;
#end

import iron.object.Object;
import iron.math.Vec4;

class AroundNavigableLocationNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);

	}

	override function get(from: Int): Dynamic {
		#if arm_navigation
			var position: Vec4 = inputs[0].get();
			var radius: Float = inputs[1].get();
		
			assert(Error, Navigation.active.navMeshes.length > 0, "No Navigation Mesh Present");
			return Navigation.active.navMeshes[0].getRandomPointAround(position, radius);
		#end
		return null;
	}
}


