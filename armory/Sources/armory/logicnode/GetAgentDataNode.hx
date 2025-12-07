package armory.logicnode;

import iron.object.Object;

class GetAgentDataNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var object: Object = inputs[0].get();

		assert(Error, object != null, "The object to naviagte should not be null");

#if arm_navigation
		var agent: armory.trait.NavAgent = object.getTrait(armory.trait.NavAgent);
		assert(Error, agent != null, "The object does not have NavAgent Trait");
		return switch(from){
			case 0: agent.speed;
			case 1: agent.turnDuration;
			case 2: @:privateAccess agent.path;
			default: null;
		}
#else
		return null;
#end
	}
}