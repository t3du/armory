package armory.logicnode;

import armory.network.PeerNetwork;

class PeerNetworkGetNode extends LogicNode {

	public function new(tree:LogicTree) {
		super(tree);
	}

	override function get(from:Int):Dynamic {
		var peerId:String = inputs[0].get();
		if (peerId == null || peerId == "") return null;

		var filterOpen:Bool = inputs[1].get();

		var connInfoMap = PeerNetwork.peerConnectionInfo.get(peerId);
		var callInfoMap = PeerNetwork.peerCallInfo.get(peerId);

		return switch (from) {
			case 0:
				if (connInfoMap == null) return [];
				var peers:Array<String> = [];
				for (remotePeerId in connInfoMap.keys()) {
					if (filterOpen) {
						var list = connInfoMap.get(remotePeerId);
						if (list != null) {
							var hasOpen = false;
							for (info in list) {
								if (info.open) {
									hasOpen = true;
									break;
								}
							}
							if (hasOpen) peers.push(remotePeerId);
						}
					}
					else {
						peers.push(remotePeerId);
					}
				}
				peers;

			case 1:
				if (connInfoMap == null) return [];
				var connections:Array<String> = [];
				for (remotePeerId in connInfoMap.keys()) {
					var list = connInfoMap.get(remotePeerId);
					if (list != null) {
						for (info in list) {
							if (!filterOpen || info.open) {
								connections.push(info.connectionId);
							}
						}
					}
				}
				connections;

			case 2:
				if (callInfoMap == null) return [];
				var calls:Array<String> = [];
				for (remotePeerId in callInfoMap.keys()) {
					var list = callInfoMap.get(remotePeerId);
					if (list != null) {
						for (info in list) {
							if (!filterOpen || info.open) {
								calls.push(info.callId);
							}
						}
					}
				}
				calls;

			case 3:
				if (connInfoMap == null) return null;
				if (!filterOpen) return connInfoMap;

				var filteredMap = new Map<String, Array<PeerConnectionInfo>>();
				for (remotePeerId in connInfoMap.keys()) {
					var list = connInfoMap.get(remotePeerId);
					if (list != null) {
						var openList:Array<PeerConnectionInfo> = [];
						for (info in list) {
							if (info.open) openList.push(info);
						}
						if (openList.length > 0) {
							filteredMap.set(remotePeerId, openList);
						}
					}
				}
				filteredMap;

			case 4:
				if (callInfoMap == null) return null;
				if (!filterOpen) return callInfoMap;

				var filteredMap = new Map<String, Array<PeerCallInfo>>();
				for (remotePeerId in callInfoMap.keys()) {
					var list = callInfoMap.get(remotePeerId);
					if (list != null) {
						var openList:Array<PeerCallInfo> = [];
						for (info in list) {
							if (info.open) openList.push(info);
						}
						if (openList.length > 0) {
							filteredMap.set(remotePeerId, openList);
						}
					}
				}
				filteredMap;

			default: null;
		}
	}
}
