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
		if (object == null || object.sound == null) return;
		
		var positionInSeconds:Float = inputs[2].get();
		if (positionInSeconds < 0) positionInSeconds = 0; 

		var volume = object.data.volume;
		var loop = object.data.loop;
		var stream = object.data.stream;
		
		object.stop();

		var channel = Audio.play(object.sound, loop, stream);
		if (channel != null) {
			object.channels.push(channel);
			channel.volume = volume;
			@:privateAccess channel.set_position(positionInSeconds);
		}
		
		runOutput(0);
	}
}
