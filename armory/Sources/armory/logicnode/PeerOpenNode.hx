package armory.logicnode;

import armory.network.PeerNetwork;

class PeerOpenNode extends LogicNode {
	var peerId: String;
	var error:Dynamic;

	public function new(tree:LogicTree) {
		super(tree);
	}

	override function run(from:Int):Void {
		peerId = null;
		error = null;
		PeerNetwork.peerOpen(inputs[1].get(), inputs[2].get(), function(id:String) {
			peerId = id;
			runOutput(0);
		}, function(error:Dynamic) {
			this.error = error;
			runOutput(1);
		});
	}

	override function get(from:Int):Dynamic {
		return from == 2 ? peerId :	error;
	}
}
