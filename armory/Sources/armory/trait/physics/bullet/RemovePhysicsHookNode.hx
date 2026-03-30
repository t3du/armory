package armory.logicnode;

import iron.object.Object;
#if arm_bullet
import armory.trait.physics.bullet.PhysicsHook;
#end

class RemovePhysicsHookNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var obj: Object = inputs[1].get();

		if (obj == null) return;

#if arm_bullet
		var hook = obj.getTrait(PhysicsHook);
		if (hook != null) {
			obj.removeTrait(hook);
		}
#end
		runOutput(0);
	}
}