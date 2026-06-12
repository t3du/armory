package armory.logicnode;

import iron.object.Object;
import armory.trait.physics.RigidBody;

class SetRigidBodyDynamicsNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var object: Object = inputs[1].get();
		var isStatic: Bool = inputs[2].get();
		var mass: Float = inputs[3].get();

		if (object == null){ runOutput(0); return; }

		#if arm_physics
		var rb = object.getTrait(RigidBody);
		if (rb != null && rb.body != null) {
			
			var finalMass = isStatic ? 0.0 : mass;
			
			rb.mass = finalMass;
			rb.staticObj = isStatic;

			var inertia = new bullet.Bt.Vector3(0, 0, 0);
			
			if (!isStatic && finalMass > 0) {
				rb.btshape.calculateLocalInertia(finalMass, inertia);
			}
			
			rb.body.setMassProps(finalMass, inertia);
			rb.body.updateInertiaTensor();
			
			rb.activate();
		}
		#end

		runOutput(0);
	}
}