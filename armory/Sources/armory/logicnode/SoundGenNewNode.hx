package armory.logicnode;

import armory.trait.internal.SoundGenerator;

class SoundGenNewNode extends LogicNode {

	var generator: SoundGenerator;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var samplingRate: Int = inputs[1].get();
		var channels: Int = inputs[2].get();
		var bitsPerSample: Int = inputs[3].get();

		generator = new SoundGenerator(samplingRate, channels, bitsPerSample);
		runOutput(0);
	}

	override function get(from: Int): Dynamic {
		return generator;
	}
}