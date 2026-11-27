package armory.logicnode;

import armory.trait.internal.SoundGenerator;

class SoundGenSetVolumeNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var generator: SoundGenerator = inputs[1].get();
		if (generator == null) { runOutput(0); return; }

		var volume: Float = inputs[2].get();
		generator.setVolume(volume);
		runOutput(0);
	}
}
