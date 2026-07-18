package armory.logicnode;

#if arm_navigation
import armory.trait.navigation.Navigation;
import armory.trait.NavMesh;
#end

import iron.object.Object;

class ReconstructNavMeshNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		#if arm_navigation
			var activeNavMesh: NavMesh = Navigation.active.navMeshes.get(inputs[1].get());
			assert(Error, activeNavMesh != null, "No Navigation Mesh Present");
			activeNavMesh.reconstructNavMesh();
		#end

		runOutput(0);
	}
}
