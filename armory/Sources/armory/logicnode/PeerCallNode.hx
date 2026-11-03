package armory.logicnode;

import armory.network.PeerNetwork;

class PeerCallNode extends LogicNode {
	var callId = "";
	var error:Dynamic;

	public function new(tree:LogicTree) {
		super(tree);
	}

	override function run(from:Int):Void {
		callId = "";
		error = null;
		var videoSource:Int = inputs[3].get();
		var audio:Bool = inputs[4].get();
		PeerNetwork.peerCall(inputs[1].get(), inputs[2].get(), videoSource, audio, inputs[5].get(), function(id:String) {
			callId = id;
			runOutput(0);
		}, function(error:Dynamic) {
			this.error = error;
			runOutput(1);
		});
	}

	override function get(from:Int):Dynamic {
		return from == 2 ? callId : error;
	}
}
