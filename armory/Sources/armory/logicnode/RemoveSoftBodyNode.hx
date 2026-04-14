package armory.logicnode;

import iron.object.Object;
import armory.trait.physics.bullet.SoftBody;

class RemoveSoftBodyNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var obj: Object = inputs[1].get();
		if (obj == null) return;

		#if arm_physics_soft
		var sb = obj.getTrait(SoftBody);
		if (sb != null) {
			obj.removeTrait(sb);
		}
		#end

		runOutput(0);
	}
}