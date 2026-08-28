package armory.logicnode;

import iron.object.SpeakerObject;
import kha.audio1.AudioChannel;

class PlaySoundNode extends LogicNode {

	var channel: AudioChannel;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var object: SpeakerObject = cast(inputs[1].get(), SpeakerObject);
		if (object == null){ runOutput(0); return; }

		if (inputs[2].get()) object.stop();
		object.data.loop = inputs[3].get();
		object.data.stream = inputs[4].get();
		channel = object.play();
		if (channel != null) tree.notifyOnUpdate(this.onUpdate);

		runOutput(0);
	}

	function onUpdate() {
		if (channel != null && channel.finished){
			channel = null;
			runOutput(1);
		}
	}
}
