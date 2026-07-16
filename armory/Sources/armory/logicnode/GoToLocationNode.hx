package armory.logicnode;

#if arm_navigation
import armory.trait.navigation.Navigation;
#end
import armory.trait.NavAgent;
import iron.object.Object;
import iron.math.Vec4;

class GoToLocationNode extends LogicNode {

	var object: Object;
	var location: Vec4;
	var speed: Float;
	var turnDuration: Float;
	var heightOffset: Float;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		object = inputs[1].get();
		location = inputs[2].get();
		speed = inputs[3].get();
		turnDuration = inputs[4].get();
		heightOffset = inputs[5].get();
		
		assert(Warning, speed >= 0, "Speed of Nav Agent should be positive");
		assert(Warning, turnDuration >= 0, "Turn Duration of Nav Agent should be positive");

		#if arm_navigation
			var from = object.transform.world.getLoc();
			var to = location;

			assert(Error, Navigation.active.navMeshes.length > 0, "No Navigation Mesh Present");
			Navigation.active.navMeshes[0].findPath(from, to, function(path: Array<Vec4>) {
				var agent: NavAgent = object.getTrait(NavAgent);
				assert(Error, agent != null, "Object does not have a NavAgent trait");
				agent.speed = speed;
				agent.turnDuration = turnDuration;
				agent.heightOffset = heightOffset;
				agent.setPath(path);
			});
		#end

		runOutput(0);
	}

}
