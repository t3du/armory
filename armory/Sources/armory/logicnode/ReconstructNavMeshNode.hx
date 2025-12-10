package armory.logicnode;

#if arm_navigation
import armory.trait.navigation.Navigation;
#end

import iron.object.Object;

class ReconstructNavMeshNode extends LogicNode {

	var object: Object;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		object = inputs[1].get();

		#if arm_navigation
			assert(Error, Navigation.active.navMeshes.length > 0, "No Navigation Mesh Present");
			Navigation.active.navMeshes[0].reconstructNavMesh();
		#end

		runOutput(0);
	}
}
