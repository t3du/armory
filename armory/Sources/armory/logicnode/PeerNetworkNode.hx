package armory.logicnode;

import armory.network.PeerNetwork;

class PeerNetworkNode extends LogicNode {
	public function new(tree:LogicTree) {
		super(tree);
	}

	override function get(from:Int):Dynamic {
		return switch (from) {
			case 0: PeerNetwork.peers;
			case 1: PeerNetwork.connections;
			case 2: PeerNetwork.peerConnections;
			case 3: PeerNetwork.peerConnectionInfo;
			default: null;
		}
	}
}
