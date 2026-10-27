package armory.logicnode;

import armory.network.PeerNetwork;

class PeerConnectionEventNode extends LogicNode {
	public var property0:String;
	var connectionId = "";
	var eventData:Dynamic;
	var connection:Dynamic;
	var eventListener:Dynamic->Void;

	public function new(tree:LogicTree) {
		super(tree);
		tree.notifyOnRemove(onRemove);
	}

	override function run(from:Int):Void {
		connectionId = inputs[1].get();
		connection = PeerNetwork.getConnection(connectionId);
		if (connection == null) {
			trace("PeerConnectionEventNode: Connection ID is not available.");
			return;
		}

		eventListener = function(value:Dynamic) {
			eventData = value;
			runOutput(0);
		}
		if (property0 == "open" && connection.open) eventListener(null);
		else connection.on(property0, eventListener);
	}

	function onRemove():Void {
		if (connection != null && eventListener != null) connection.removeListener(property0, eventListener);
	}

	override function get(from:Int):Dynamic {
		return eventData;
	}
}
