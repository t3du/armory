package armory.logicnode;

import iron.object.Object;
#if arm_bullet
import armory.trait.physics.bullet.PhysicsHook;
#end

class AddPhysicsHookNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var obj: Object = inputs[1].get();
		var target: Object = inputs[2].get();
		var verts: Array<Float> = inputs[3].get();

		if (obj == null || target == null) return;

#if arm_bullet
		var hook = obj.getTrait(PhysicsHook);
		if (hook == null) {
			hook = new PhysicsHook(target.name, verts);
			obj.addTrait(hook);
		}
#end
		runOutput(0);
	}
}