package armory.logicnode;

import armory.trait.internal.SoundGenerator;

class SoundGenDSPFilterNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var generator: SoundGenerator = inputs[1].get();
		if (generator == null) { runOutput(0); return; }

		var mode: String = switch(inputs[2].get()){
			case 0: 'Low';
			case 1: 'Hight';
			default: 'Band';
		}

		var freq1: Float = inputs[3].get();
		var freq2: Float = inputs[4].get();
		generator.playDSPFilter(mode, freq1, freq2, function() { runOutput(1); });
		runOutput(0);
	}

}