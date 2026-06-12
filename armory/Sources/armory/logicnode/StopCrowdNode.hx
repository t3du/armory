package armory.logicnode;

import iron.object.Object;

#if arm_navigation
import armory.trait.navigation.Navigation;
#end

class StopCrowdNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var object: Object = inputs[1].get();

		if (object == null){ runOutput(0); return; }

		#if arm_navigation
			assert(Error, Navigation.active.navMeshes.length > 0, "No Navigation Mesh Present");
			var crowdAgent: armory.trait.NavCrowd = object.getTrait(armory.trait.NavCrowd);
			assert(Error, crowdAgent != null, "Object does not have a NavCrowd trait");
			crowdAgent.crowdAgentTeleport(object.transform.world.getLoc());
		#end

		runOutput(0);
	}
}
