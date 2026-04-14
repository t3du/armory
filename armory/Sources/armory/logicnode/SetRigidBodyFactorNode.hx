package armory.logicnode;

import iron.object.Object;
import iron.math.Vec4;
import armory.trait.physics.RigidBody;
#if arm_bullet
import bullet.Bt.Vector3;
#end

class SetRigidBodyFactorNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var obj: Object = inputs[1].get();
		var linFac: Vec4 = inputs[2].get();
		var angFac: Vec4 = inputs[3].get();

		if (obj == null) return;

		#if arm_physics
		var rb = obj.getTrait(RigidBody);
		if (rb != null) {
			var lf = new Vector3(linFac.x, linFac.y, linFac.z);
			var af = new Vector3(angFac.x, angFac.y, angFac.z);
			
			rb.body.setLinearFactor(lf);
			rb.body.setAngularFactor(af);
			rb.activate();
		}
		#end

		runOutput(0);
	}
}