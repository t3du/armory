package armory.logicnode;

import iron.object.Object;
import iron.math.Vec4;
import armory.trait.physics.RigidBody;

using armory.object.TransformExtension;

class SetRigidBodyVelocityNode extends LogicNode {

	public var property0: String;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var object: Object = inputs[1].get();
		if (object == null) {
			runOutput(0);
			return;
		}

#if arm_physics
		var rb: RigidBody = object.getTrait(RigidBody);
		if (rb != null) {
			rb.activate();
			
			switch (property0) {
				case "Both":
					var linear: Vec4 = inputs[2].get();
					var localLinear: Bool = inputs[3].get();
					var angular: Vec4 = inputs[4].get();
					var localAngular: Bool = inputs[5].get();
					if (localLinear)
						linear = object.transform.worldVecToOrientation(linear);
					rb.setLinearVelocity(linear.x, linear.y, linear.z);
					if (localAngular)
						angular = object.transform.worldVecToOrientation(angular);
					rb.setAngularVelocity(angular.x, angular.y, angular.z);
				case "Linear":
					var linear: Vec4 = inputs[2].get();
					var localLinear: Bool = inputs[3].get();
					if (localLinear)
						linear = object.transform.worldVecToOrientation(linear);
					rb.setLinearVelocity(linear.x, linear.y, linear.z);
				case "Angular":
					var angular: Vec4 = inputs[4].get();
					var localAngular: Bool = inputs[5].get();
					if (localAngular)
						angular = object.transform.worldVecToOrientation(angular);
					rb.setAngularVelocity(angular.x, angular.y, angular.z);
			}
		}
#end

		runOutput(0);
	}
}