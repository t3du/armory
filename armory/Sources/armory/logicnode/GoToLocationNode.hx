package armory.logicnode;

#if arm_navigation
import armory.trait.navigation.Navigation;
import armory.trait.NavMesh;
import armory.trait.NavAgent;
#end

import iron.object.Object;
import iron.math.Vec4;

class GoToLocationNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		
		var navMeshId: String = inputs[1].get();
		var object: Object = inputs[2].get();
		var location: Vec4 = inputs[3].get();
		var speed: Float = inputs[4].get();
		var turnDuration: Float = inputs[5].get();
		var heightOffset: Float = inputs[6].get();
		
		assert(Warning, speed >= 0, "Speed of Nav Agent should be positive");
		assert(Warning, turnDuration >= 0, "Turn Duration of Nav Agent should be positive");

		#if arm_navigation
			var activeNavMesh: NavMesh = Navigation.active.navMeshes.get(navMeshId);
			assert(Error, activeNavMesh != null, "No Navigation Mesh Present");

			activeNavMesh.findPath(object.transform.world.getLoc(), location, function(path: Array<Vec4>) {
				var agent: NavAgent = object.getTrait(NavAgent);
				assert(Error, agent != null, "Object does not have a NavAgent trait");
				agent.navMeshId = navMeshId;
				agent.speed = speed;
				agent.turnDuration = turnDuration;
				agent.heightOffset = heightOffset;
				agent.setPath(path);
			});
		#end

		runOutput(0);
	}

}
