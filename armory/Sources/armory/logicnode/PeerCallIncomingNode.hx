package armory.logicnode;

import armory.network.PeerNetwork;

class PeerCallIncomingNode extends LogicNode {
	var peerId = "";
	var callId = "";
	var remotePeerId = "";
	var metadata:Dynamic;
	var callListener:Dynamic->Void;

	public function new(tree:LogicTree) {
		super(tree);
		tree.notifyOnRemove(onRemove);
	}

	override function run(from:Int):Void {
		if (callListener != null) PeerNetwork.removePeerEventListener(peerId, "call", callListener);
		peerId = inputs[1].get();
		if (PeerNetwork.getPeer(peerId) == null) {
			trace("PeerCallIncomingNode: Peer ID To is not available.");
			callListener = null;
			return;
		}

		callListener = function(call:Dynamic) {
			callId = call.connectionId;
			remotePeerId = call.peer;
			metadata = call.metadata;
			runOutput(0);
		};
		PeerNetwork.addPeerEventListener(peerId, "call", callListener);
	}

	function onRemove():Void {
		if (callListener != null) PeerNetwork.removePeerEventListener(peerId, "call", callListener);
	}

	override function get(from:Int):Dynamic {
		return switch (from) {
			case 1: callId;
			case 2: remotePeerId;
			case 3: metadata;
			default: null;
		}
	}
}
