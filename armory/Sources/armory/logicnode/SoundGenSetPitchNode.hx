package armory.logicnode;

import armory.trait.internal.SoundGenerator;

class SoundGenSetPitchNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var generator: SoundGenerator = inputs[1].get();
		if (generator == null) { runOutput(0); return; }

		var pitch: Float = inputs[2].get();
		generator.setPitch(pitch);
		runOutput(0);
	}

}
