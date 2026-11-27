package armory.logicnode;

import armory.trait.internal.SoundGenerator;
import iron.math.Vec4;
import iron.object.CameraObject;

class SoundGenHRTFNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var generator: SoundGenerator = inputs[1].get();
		if (generator == null) { runOutput(0); return; }

		var camera: CameraObject = inputs[2].get();
		var soundPos: Vec4 = inputs[3].get();
		if (camera == null || soundPos == null) { runOutput(0); return; }

		generator.playHRTFPanner(camera, soundPos, function() { runOutput(1); });
		runOutput(0);
	}

}
