package armory.logicnode;

import iron.object.Object;
import armory.trait.physics.bullet.SoftBody;

class AddSoftBodyNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var obj: Object = inputs[1].get();
		if (obj == null) return;

		var shape: Int = inputs[2].get(); // 0: Cloth, 1: Volume
		var bend: Float = inputs[3].get();
		var mass: Float = inputs[4].get();
		var margin: Float = inputs[5].get();
		var friction: Float = inputs[6].get();
		var damping: Float = inputs[7].get();
		var pressure: Float = inputs[8].get();
		var lStiff: Float = inputs[9].get();
		var aStiff: Float = inputs[10].get();

		#if arm_physics_soft
		var sb: SoftBody = obj.getTrait(SoftBody);
		if (sb == null) {
			sb = new SoftBody(shape, bend, mass, margin, friction, damping, lStiff, aStiff, pressure);
			obj.addTrait(sb);
		}
		#end

		runOutput(0);
	}
}