package armory.logicnode;

import iron.object.Object;
import iron.object.MeshObject;

class CurveGuideNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		#if arm_cpu_particles
		var object: Object = inputs[1].get();
		var slot: Int = inputs[2].get();

		if (object == null){ runOutput(0); return; }

		var mo: MeshObject = cast object;
	
		var psys = mo.particleSystems != null ? mo.particleSystems[slot] : null;
			
		if (psys == null){ runOutput(0); return; }

		psys.curveGuides = inputs[3].get();
		psys.curveGuideStrength = inputs[4].get();
		psys.curveGuideSpeed = inputs[5].get();

		#end

		runOutput(0);
	}
}
