package armory.logicnode;

import armory.network.PeerNetwork;

class CallCloseNode extends LogicNode {
	var error:Dynamic;

	public function new(tree:LogicTree) {
		super(tree);
	}

	override function run(from:Int):Void {
		error = null;
		if (PeerNetwork.peerCallClose(inputs[1].get(), function(error:Dynamic) {
			this.error = error;
			runOutput(1);
		})) runOutput(0);
	}

	override function get(from:Int):Dynamic {
		return error;
	}
}
