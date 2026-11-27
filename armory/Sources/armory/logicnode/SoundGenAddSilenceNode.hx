package armory.logicnode;

import armory.trait.internal.SoundGenerator;

class SoundGenAddSilenceNode extends LogicNode {

	var generator: SoundGenerator;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		generator = inputs[1].get();
		if (generator == null) { runOutput(0); return; }

		var duration: Float = inputs[2].get();
		generator.addSilence(duration);
		runOutput(0);
	}

	override function get(from: Int): Dynamic {
		return generator;
	}
}