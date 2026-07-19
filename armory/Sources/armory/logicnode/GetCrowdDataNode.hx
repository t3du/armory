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
				case 2: crowdAgent.crowdAgentMaxSpeed();
				case 3: crowdAgent.crowdAgentMaxAcceleration();
				case 4: crowdAgent.turnSpeed;
				case 5: crowdAgent.crowdAgentPosition();
				case 6: crowdAgent.crowdAgentNextPath();
				case 7: @:privateAccess crowdAgent.agentID;
				case 8: crowdAgent.crowdAgentPath();
				default: null;
			}
		#else
			return null;

		#end
	}
}