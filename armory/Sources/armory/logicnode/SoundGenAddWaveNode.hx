package armory.logicnode;

import armory.trait.internal.SoundGenerator;

class SoundGenAddWaveNode extends LogicNode {

	var generator: SoundGenerator;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		generator = inputs[1].get();
		if (generator == null) { runOutput(0); return; }

		var waveType: String = switch(inputs[1].get()){
			case 0: 'square';
			case 1: 'sawtooth';
			case 2: 'triangle';
			default: 'sine';
		}
		
		var waveType: String = inputs[2].get();
		var frequency: Float = inputs[3].get();
		var duration: Float = inputs[4].get();

		generator.addWave(waveType, frequency, duration);
		runOutput(0);
	}

	override function get(from: Int): Dynamic {
		return inputs[1].get();
	}
}