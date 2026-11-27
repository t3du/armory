package armory.logicnode;

import armory.trait.internal.SoundGenerator;

class SoundGenSemitonesToFreqNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var semitones: Int = inputs[0].get();
		var baseA4: Float = inputs[1].get();
		return SoundGenerator.semitonesToFreq(semitones, baseA4);
	}
}