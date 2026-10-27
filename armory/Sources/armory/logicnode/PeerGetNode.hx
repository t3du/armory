package armory.logicnode;

import armory.network.PeerNetwork;

class PeerGetNode extends LogicNode {
	public function new(tree:LogicTree) {
		super(tree);
	}

	override function get(from:Int):Dynamic {
		var peerId:String = inputs[0].get();
		var peer = PeerNetwork.getPeer(peerId);
		if (peer == null) return null;

		return switch (from) {
			case 0: peer.open;
			case 1: peer.disconnected;
			case 2: peer.destroyed;
			default: null;
		}
	}
}
