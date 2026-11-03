package armory.logicnode;

import armory.network.PeerNetwork;

class PeerDestroyNode extends LogicNode {
	public function new(tree:LogicTree) {
		super(tree);
	}

	override function run(from:Int):Void {
		PeerNetwork.peerDestroy(inputs[1].get());
		runOutput(0);
	}
}
