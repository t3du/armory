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
		var inputVerts: Dynamic = inputs[3].get();

		var flattenedVerts: Array<Float> = [];
		
		if (Std.isOfType(inputVerts, Array)) {
			var vArray: Array<Dynamic> = cast inputVerts;
			for (v in vArray) {
				if (v.x != null) {
					flattenedVerts.push(v.x);
					flattenedVerts.push(v.y);
					flattenedVerts.push(v.z);
				} 
				else if (v[0] != null) {
					flattenedVerts.push(v[0]);
					flattenedVerts.push(v[1]);
					flattenedVerts.push(v[2]);
				}
			}
		}

#if arm_bullet
		var hook = obj.getTrait(PhysicsHook);
		if (hook == null) {
			hook = new PhysicsHook(target.name, flattenedVerts);
			obj.addTrait(hook);
		}
#end
		runOutput(0);
	}
}