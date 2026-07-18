package armory.logicnode;

import iron.object.Object;

#if arm_navigation
import armory.trait.navigation.Navigation;
import armory.trait.NavAgent;
#end

class StopAgentNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var object: Object = inputs[1].get();

		if (object == null){ runOutput(0); return; }

		#if arm_navigation
			var agent: NavAgent = object.getTrait(NavAgent);
			assert(Error, agent != null, "Object does not have a NavAgent trait");
			agent.stop();
		#end

		runOutput(0);
	}
}
