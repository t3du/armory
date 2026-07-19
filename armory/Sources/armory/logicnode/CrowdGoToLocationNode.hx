package armory.logicnode;

#if arm_navigation
import armory.trait.navigation.Navigation;
import armory.trait.NavMesh;
import armory.trait.NavCrowd;
#end

import iron.object.Object;
import iron.math.Vec4;

class CrowdGoToLocationNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var navMeshId: String = inputs[1].get();
		var object: Object = inputs[2].get();
		var location: Vec4 = inputs[3].get();
		var maxSpeed: Float = inputs[4].get();
		var maxAcceleration: Float = inputs[5].get();
		var turnSpeed: Float = inputs[6].get();
		
		#if arm_navigation
			var activeNavMesh: NavMesh = Navigation.active.navMeshes.get(navMeshId);
			assert(Error, activeNavMesh != null, "No Navigation Mesh Present");

			var crowdAgent: NavCrowd = object.getTrait(NavCrowd);
			assert(Error, crowdAgent != null, "Object does not have a NavCrowd trait");
			crowdAgent.crowdAgentSetMaxSpeed(maxSpeed);
			crowdAgent.crowdAgentSetMaxAcceleration(maxAcceleration);
			crowdAgent.turnSpeed = turnSpeed;
			crowdAgent.crowdAgentGoto(location);
		#end
		runOutput(0);
	}
}
