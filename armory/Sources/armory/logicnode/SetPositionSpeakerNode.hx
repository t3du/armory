package armory.logicnode;

import iron.object.SpeakerObject;
import kha.audio1.AudioChannel;
import iron.system.Audio;

class SetPositionSpeakerNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var object: SpeakerObject = cast(inputs[1].get(), SpeakerObject);
		if (object == null || object.sound == null){ runOutput(0); return; }

		object.setPosition(inputs[2].get());
		
		runOutput(0);
	}
}
