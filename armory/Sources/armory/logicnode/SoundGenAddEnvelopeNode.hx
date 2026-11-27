package armory.logicnode;

import armory.trait.internal.SoundGenerator;

class SoundGenAddEnvelopeNode extends LogicNode {

	var generator: SoundGenerator;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		generator = inputs[1].get();
		if (generator == null) { runOutput(0); return; }

		var frequency: Float = inputs[2].get();
		var duration: Float = inputs[3].get();
		var attack: Float = inputs[4].get();
		var decay: Float = inputs[5].get();
		var sustain: Float = inputs[6].get();
		var release: Float = inputs[7].get();
		generator.addEnvelope(frequency, duration, attack, decay, sustain, release);
		runOutput(0);
	}

	override function get(from: Int): Dynamic {
		return generator;
	}
}