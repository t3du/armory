package armory.logicnode;

import iron.object.Object;

#if arm_navigation
import armory.trait.navigation.Navigation;
import armory.trait.NavCrowd;
#end

class GetCrowdDataNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var object: Object = inputs[0].get();

		#if arm_navigation
			var crowdAgent: NavCrowd = object.getTrait(NavCrowd);
			if (crowdAgent == null) return null;
			return switch(from){
				case 0: crowdAgent.navMeshId;
				case 1: crowdAgent.crowdAgentVelocity();
				case 2: crowdAgent.crowdAgentPosition();
				case 3: crowdAgent.crowdAgentNextPath();
				case 4: @:privateAccess crowdAgent.agentID;
				case 5: crowdAgent.crowdAgentPath();
				default: null;
			}
		#else
			return null;

		#end
	}
}