package armory.logicnode;

import iron.object.SpeakerObject;
import kha.audio1.AudioChannel;

class GetSpeakerDataNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var object: SpeakerObject = cast(inputs[0].get(), SpeakerObject);

		switch(from){
			case 0:
				return object.volume;
			case 1:
				return object.data.pitch;
			case 2:
				return object.channels.length;
			case 3:
				var len: Array<Float> = null;
				if (object.channels.length > 0){
					len = [];
					for (channel in object.channels)
						len.push(channel.length);
				}
				return len;
			case 4:
				var pos: Array<Float> = null;
				if (object.channels.length > 0){
					pos = [];
					for (channel in object.channels)
						pos.push(channel.position);
				}
				return pos;
			default:
				return null;
		}
	}
}
