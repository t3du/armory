package armory.logicnode;

import armory.network.PeerNetwork;

class CallCloseNode extends LogicNode {
	public function new(tree:LogicTree) {
		super(tree);
	}

	override function run(from:Int):Void {
		if (PeerNetwork.peerCallClose(inputs[1].get())) runOutput(0);
	}
}
