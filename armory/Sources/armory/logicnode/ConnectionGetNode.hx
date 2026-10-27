package armory.logicnode;

import armory.network.PeerNetwork;

class ConnectionGetNode extends LogicNode {
	public function new(tree:LogicTree) {
		super(tree);
	}

	override function get(from:Int):Dynamic {
		var connectionId:String = inputs[0].get();
		var connection = PeerNetwork.getConnection(connectionId);
		if (connection == null) return null;

		return switch (from) {
			case 0: connection.peer;
			case 1: connection.label;
			case 2: connection.metadata;
			case 3: connection.open;
			default: null;
		}
	}
}
