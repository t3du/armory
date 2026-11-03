package armory.logicnode;

import armory.network.PeerNetwork;

class CallGetNode extends LogicNode {
	public function new(tree:LogicTree) {
		super(tree);
	}

	override function get(from:Int):Dynamic {
		var call = PeerNetwork.getCall(inputs[0].get());
		if (call == null) return null;

		return switch (from) {
			case 0: call.peer;
			case 1: call.metadata;
			case 2: call.open;
			case 3: call.localStream;
			case 4: call.remoteStream;
			default: null;
		}
	}
}
