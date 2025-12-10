package armory.logicnode;

import iron.object.Object;

#if arm_navigation
import armory.trait.navigation.Navigation;
#end

class GetCrowdDataNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var object: Object = inputs[0].get();

		#if arm_navigation
			assert(Error, Navigation.active.navMeshes.length > 0, "No Navigation Mesh Present");
			var crowdAgent: armory.trait.NavCrowd = object.getTrait(armory.trait.NavCrowd);
			assert(Error, crowdAgent != null, "Object does not have a NavCrowd trait");
			return switch(from){
				case 0: crowdAgent.crowdAgentVelocity();
				case 1: crowdAgent.crowdAgentPosition();
				case 2: crowdAgent.crowdAgentNextPath();
				case 3: @:privateAccess crowdAgent.agentID;
				default: null;
			}
		#else
			return null;
		#end
	}
}