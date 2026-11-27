package armory.logicnode;

import armory.trait.internal.SoundGenerator;

class SoundGenAddHarmonicsNode extends LogicNode {

	var generator: SoundGenerator;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		generator = inputs[1].get();
		if (generator == null) { runOutput(0); return; }

		var frequency: Float = inputs[2].get();
		var duration: Float = inputs[3].get();
		var count: Int = inputs[4].get();
		generator.addHarmonics(frequency, duration, count);
		runOutput(0);
	}

	override function get(from: Int): Dynamic {
		return generator;
	}

}