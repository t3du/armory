package armory.logicnode;

import armory.trait.internal.SoundGenerator;

class SoundGenNoteToFreqNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var midiNote: Int = inputs[0].get();
		var baseA4: Float = inputs[1].get();
		return SoundGenerator.noteToFreq(midiNote, baseA4);
	}
}