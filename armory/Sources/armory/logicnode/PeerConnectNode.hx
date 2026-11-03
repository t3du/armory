package armory.logicnode;

import armory.network.PeerNetwork;

class PeerConnectNode extends LogicNode {
	var connectionId = "";
	var error:Dynamic;

	public function new(tree:LogicTree) {
		super(tree);
	}

	override function run(from:Int):Void {
		connectionId = "";
		error = null;
		PeerNetwork.peerConnect(inputs[1].get(), inputs[2].get(), inputs[3].get(), inputs[4].get(), inputs[5].get(), function(id:String) {
			connectionId = id;
			runOutput(0);
		}, function(error:Dynamic) {
			this.error = error;
			runOutput(1);
		});
	}

	override function get(from:Int):Dynamic {
		return from == 2 ? connectionId : error;
	}
}
