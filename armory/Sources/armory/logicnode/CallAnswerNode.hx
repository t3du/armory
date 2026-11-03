package armory.logicnode;

import armory.network.PeerNetwork;

class CallAnswerNode extends LogicNode {
	var error:Dynamic;

	public function new(tree:LogicTree) {
		super(tree);
	}

	override function run(from:Int):Void {
		error = null;
		var videoSource:Int = inputs[2].get();
		var audio:Bool = inputs[3].get();
		PeerNetwork.peerCallAnswer(inputs[1].get(), videoSource, audio, function() {
			runOutput(0);
		}, function(error:Dynamic) {
			this.error = error;
			runOutput(1);
		});
	}

	override function get(from:Int):Dynamic {
		return error;
	}
}
