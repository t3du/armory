package armory.logicnode;

import armory.network.PeerNetwork;

class PeerReconnectNode extends LogicNode {
	public function new(tree:LogicTree) {
		super(tree);
	}

	override function run(from:Int):Void {
		PeerNetwork.peerReconnect(inputs[1].get());
		runOutput(0);
	}
}
