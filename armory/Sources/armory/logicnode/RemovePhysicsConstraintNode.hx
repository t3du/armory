package armory.logicnode;

import iron.object.Object;
#if arm_bullet
import armory.trait.physics.PhysicsConstraint;
#end

class RemovePhysicsConstraintNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var pivotObject: Object = inputs[1].get();

		if (pivotObject == null) return;

#if arm_bullet
		var con = pivotObject.getTrait(PhysicsConstraint);
		
		if (con != null) {
			pivotObject.removeTrait(con);
		}
#end
		runOutput(0);
	}
}