package armory.logicnode;

import armory.network.PeerNetwork;

class ConnectionSendNode extends LogicNode {
	var error:Dynamic;

	public function new(tree:LogicTree) {
		super(tree);
	}

	override function run(from:Int):Void {
		error = null;
		var connectionId:String = inputs[1].get();
		var data:Dynamic = inputs[2].get();
		if (PeerNetwork.connectionSend(connectionId, data, function(error:Dynamic) {
			this.error = error;
			runOutput(1);
		})) runOutput(0);
	}

	override function get(from:Int):Dynamic {
		return error;
	}
}
