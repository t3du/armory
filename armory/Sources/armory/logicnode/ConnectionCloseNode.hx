package armory.logicnode;

import armory.network.PeerNetwork;

class ConnectionCloseNode extends LogicNode {
	public function new(tree:LogicTree) {
		super(tree);
	}

	override function run(from:Int):Void {
		if (PeerNetwork.connectionClose(inputs[1].get())) runOutput(0);
	}
}
