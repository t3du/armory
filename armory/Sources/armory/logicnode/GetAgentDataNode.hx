package armory.logicnode;

import iron.object.Object;

#if arm_navigation
import armory.trait.navigation.Navigation;
import armory.trait.NavAgent;
#end

class GetAgentDataNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var object: Object = inputs[0].get();

		#if arm_navigation
			var agent: NavAgent = object.getTrait(NavAgent);
			if (agent == null) return null;
			return switch(from){
				case 0: agent.navMeshId;
				case 1: agent.speed;
				case 2: agent.turnDuration;
				case 3: @:privateAccess agent.path;
				default: null;
			}
		#else
			return null;
		#end
	}
}