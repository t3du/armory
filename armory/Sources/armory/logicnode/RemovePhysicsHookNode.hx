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
		if (softBody != null && softBody.body != null) {
			@:privateAccess
			var oldNodes = softBody.body.get_m_nodes();
			var count = oldNodes.size();

			var savedData = [];
			for (i in 0...count) {
				var pos = oldNodes.at(i).get_m_x();
				var nor = oldNodes.at(i).get_m_n();
				savedData.push({
					x: pos.x(), y: pos.y(), z: pos.z(),
					nx: nor.x(), ny: nor.y(), nz: nor.z()
				});
			}

			@:privateAccess
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

			@:privateAccess {
				newSoftBody.init();
				newSoftBody._init = null;

				if (newSoftBody.body != null) {
					var newNodes = newSoftBody.body.get_m_nodes();
					for (i in 0...count) {
						var d = savedData[i];
						newNodes.at(i).get_m_x().setValue(d.x, d.y, d.z);
						newNodes.at(i).get_m_n().setValue(d.nx, d.ny, d.nz);
					}
					newSoftBody.update();
				}
			}
		}
#end
#end
		runOutput(0);
	}
}