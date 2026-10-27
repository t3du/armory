package armory.logicnode;

import armory.network.PeerNetwork;

class PeerEventNode extends LogicNode {
	public var property0:String;
	var peerId = "";
	var connectionId = "";
	var peerIdFromConnection = "";
	var label = "";
	var metadata:Dynamic;
	var data:Dynamic;
	var error:Dynamic;
	var peerDataListener:Dynamic->Dynamic->Void;
	var peerEventListener:Dynamic->Void;

	public function new(tree:LogicTree) {
		super(tree);
		tree.notifyOnRemove(onRemove);
	}

	override function run(from:Int):Void {
		peerId = inputs[1].get();
		if (property0 == "data") {
			peerDataListener = function(connection:Dynamic, value:Dynamic) {
				connectionId = connection.connectionId;
				peerIdFromConnection = connection.peer;
				label = connection.label;
				metadata = connection.metadata;
				data = value;
				runOutput(0);
			};
			PeerNetwork.addPeerDataListener(peerId, peerDataListener);
		}
		else {
			peerEventListener = function(value:Dynamic) {
				if (property0 == "connection") {
					connectionId = value.connectionId;
					peerIdFromConnection = value.peer;
					label = value.label;
					metadata = value.metadata;
				}
				else if (property0 == "error") error = value;
				runOutput(0);
			};
			PeerNetwork.addPeerEventListener(peerId, property0, peerEventListener);
		}
	}

	function onRemove():Void {
		if (peerDataListener != null) PeerNetwork.removePeerDataListener(peerId, peerDataListener);
		if (peerEventListener != null) PeerNetwork.removePeerEventListener(peerId, property0, peerEventListener);
	}

	override function get(from:Int):Dynamic {
		return switch (property0) {
			case "connection", "data":
				switch (from) {
					case 1: connectionId;
					case 2: peerIdFromConnection;
					case 3: label;
					case 4: metadata;
					case 5: data;
					default: null;
				}
			case "error": error;
			default: null;
		}
	}
}
