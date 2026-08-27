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
				return object.channels.length > 0 ? object.channels[0].length : 0;
			case 3:
				return object.channels.length > 0 ? object.channels[0].position : 0;
			default:
				return null;
		}
	}
}
