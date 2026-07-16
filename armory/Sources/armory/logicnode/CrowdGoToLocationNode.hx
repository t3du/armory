package armory.logicnode;

#if arm_navigation
import armory.trait.navigation.Navigation;
import armory.trait.NavCrowd;
#end

import iron.object.Object;
import iron.math.Vec4;

class CrowdGoToLocationNode extends LogicNode {

	var object: Object;
	var location: Vec4;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		object = inputs[1].get();
		location = inputs[2].get();
		
		#if arm_navigation
			assert(Error, Navigation.active.navMeshes.length > 0, "No Navigation Mesh Present");
			var crowdAgent: NavCrowd = object.getTrait(NavCrowd);
			assert(Error, crowdAgent != null, "Object does not have a NavCrowd trait");
			crowdAgent.crowdAgentGoto(location);
		#end
		runOutput(0);
	}
}
