package armory.logicnode;

import iron.object.SpeakerObject;
import kha.audio1.AudioChannel;

class GetPositionSpeakerNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var object: SpeakerObject = cast(inputs[0].get(), SpeakerObject);
		if (object == null || object.sound == null) return 0.0;
		
		if (object.channels.length == 0) return 0.0;
		
		var channel = object.channels[0];
		
		var position = 0.0;
		if (channel != null) {
			position = @:privateAccess channel.get_position();
		}
		
		return position;
	}
}
