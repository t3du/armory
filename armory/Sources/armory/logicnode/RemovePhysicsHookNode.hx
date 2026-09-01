package armory.logicnode;

import iron.object.Object;
#if arm_bullet
import armory.trait.physics.bullet.PhysicsHook;
#if arm_physics_soft
import armory.trait.physics.SoftBody;
#end
#end

class RemovePhysicsHookNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var obj: Object = inputs[1].get();

		if (obj == null){ runOutput(0); return; }

#if arm_bullet
		var hook = obj.getTrait(PhysicsHook);
		if (hook != null) {
			hook.removePhysicsHook();
			obj.removeTrait(hook);
		}

//hack: SB loses collision after removing hook
#if arm_physics_soft
		var softBody = obj.getTrait(SoftBody);
		if (softBody != null) {
			var newSoftBody = new SoftBody(
				softBody.shape,
				softBody.bend,
				softBody.mass,
				softBody.margin,
				softBody.friction,
				softBody.damping,
				softBody.linearStiffness,
				softBody.angularStiffness,
				softBody.pressure
			);
			obj.removeTrait(softBody);
			obj.addTrait(newSoftBody);
		}
#end
#end
		runOutput(0);
	}
}