package armory.logicnode;

import iron.object.SpeakerObject;

class SetPitchSoundNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var object: SpeakerObject = cast(inputs[1].get(), SpeakerObject);
		if (object == null){ runOutput(0); return; }
		object.data.pitch = inputs[2].get();
		object.sound.sampleRate = Std.int(object.sampleRate * object.data.pitch);
		runOutput(0);
	}
}
