package armory.logicnode;

import armory.network.PeerNetwork;

class PeerStartNode extends LogicNode {
	var peerId: String;

	public function new(tree:LogicTree) {
		super(tree);
	}

	override function run(from:Int):Void {
		PeerNetwork.peerStart(inputs[1].get(), function(id:String) {
			peerId = id;
			runOutput(0);
		});
	}

	override function get(from:Int):Dynamic {
		return peerId;
	}
}
