package armory.logicnode;

import iron.object.Object;
import iron.object.MeshObject;
import iron.data.MeshData;
import armory.trait.physics.bullet.SoftBody;

class RemoveSoftBodyNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var obj: Object = inputs[1].get();
		if (obj == null) { runOutput(0); return; }

		#if arm_physics_soft
		var restore: Bool = inputs[2].get();
		var sb = obj.getTrait(SoftBody);
		if (sb != null) {
			sb.remove();
			if (restore) {
				var mo = cast(obj, MeshObject);
				if (mo != null && mo.data != null) {
					new MeshData(mo.data.raw, function(data) {
						mo.setData(data);
						mo.transform.scaleWorld = 1.0;
						mo.transform.buildMatrix();
					});
				}
			}
		}
		#end

		runOutput(0);
	}
}