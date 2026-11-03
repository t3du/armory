package armory.logicnode;

import armory.network.PeerNetwork;

class PeerDisconnectNode extends LogicNode {
	public function new(tree:LogicTree) {
		super(tree);
	}

	override function run(from:Int):Void {
		PeerNetwork.peerDisconnect(inputs[1].get());
		runOutput(0);
	}
}
