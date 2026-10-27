package armory.network;

class PeerNetwork {
	public static var peers:Map<String, Dynamic> = new Map();
	public static var connections:Map<String, Dynamic> = new Map();
	public static var peerConnections:Map<String, Array<Dynamic>> = new Map();
	public static var peerConnectionInfo:Map<String, Map<String, Array<PeerConnectionInfo>>> = new Map();
	static var peerDataListeners:Map<String, Array<Dynamic->Dynamic->Void>> = new Map();
	static var peerDataBindings:Array<PeerDataBinding> = [];

	public static function peerOpen(id:String, options:Dynamic, onReady:String->Void, onError:Dynamic->Void):Void {
		if (js.Syntax.code("window.peerjs") == null) {
			iron.data.Data.getBlob("peerjs.min.js", function(blob:kha.Blob) {
				var script = js.Browser.document.createScriptElement();
				script.text = blob.bytes.toString();
				js.Browser.document.head.appendChild(script);
				peerOpen(id, options, onReady, onError);
			});
			return;
		}
		var peerId:Dynamic = null;
		try {
			if (options == null) {
				peerId = id == ""
					? js.Syntax.code("new window.peerjs.Peer()")
					: js.Syntax.code("new window.peerjs.Peer({0})", id);
			}
			else {
				peerId = id == ""
					? js.Syntax.code("new window.peerjs.Peer({0})", options)
					: js.Syntax.code("new window.peerjs.Peer({0}, {1})", id, options);
			}
		}
		catch (error:Dynamic) {
			onError(error);
			return;
		}
		var opened = false;
		var peerErrorListener:Dynamic->Void = function(error:Dynamic) {
			if (!opened) onError(error);
		};
		var peerCloseListener:Void->Void = function() {
			if (!opened) onError("PeerNetwork: Peer closed before opening.");
		};
		peerId.on("error", peerErrorListener);
		peerId.on("open", function(Id:String) {
			opened = true;
			peerId.removeListener("error", peerErrorListener);
			peerId.removeListener("close", peerCloseListener);
			peers.set(Id, peerId);
			if (onReady != null) onReady(Id);
		});
		peerId.on("close", peerCloseListener);
		peerId.on("connection", function(connection:Dynamic) {
			trackConnection(peerId.id, connection);
		});
	}

	public static function peerConnect(peerIdFrom:String, peerIdTo:String, label:String, connectionId:String, metadata:Dynamic, onOpen:String->Void, onError:Dynamic->Void):Void {
		var peer = peers.get(peerIdFrom);
		if (peer == null) {
			onError("PeerNetwork: Peer ID From is not available.");
			return;
		}
		var connection:Dynamic;
		var settled = false;
		var peerErrorListener:Dynamic->Void = null;
		peerErrorListener = function(error:Dynamic) {
			var message = Std.string(Reflect.field(error, "message"));
			if (!settled && Reflect.field(error, "type") == "peer-unavailable" && message.indexOf(peerIdTo) >= 0) {
				settled = true;
				peer.removeListener("error", peerErrorListener);
				onError(error);
			}
		};
		try {
			peer.on("error", peerErrorListener);
			connection = peer.connect(peerIdTo, {label: label, connectionId: connectionId, metadata: metadata});
		}
		catch (error:Dynamic) {
			peer.removeListener("error", peerErrorListener);
			onError(error);
			return;
		}
		if (connection == null) {
			peer.removeListener("error", peerErrorListener);
			onError("PeerNetwork: PeerJS did not create a connection.");
			return;
		}
		trackConnection(peerIdFrom, connection);
		connection.on("open", function() {
			if (settled) return;
			settled = true;
			peer.removeListener("error", peerErrorListener);
			if (onOpen != null) onOpen(connection.connectionId);
		});
		connection.on("error", function(error:Dynamic) {
			if (settled) return;
			settled = true;
			peer.removeListener("error", peerErrorListener);
			onError(error);
		});
		connection.on("close", function() {
			peer.removeListener("error", peerErrorListener);
			if (!settled) {
				settled = true;
				onError("PeerNetwork: Connection closed before opening.");
			}
		});
	}

	public static function peerSend(connectionId:String, data:Dynamic, onError:Dynamic->Void):Bool {
		var connection = connections.get(connectionId);
		if (connection == null) {
			onError("PeerNetwork: Connection ID is not available.");
			return false;
		}
		if (!connection.open) {
			onError("PeerNetwork: Connection is not open.");
			return false;
		}
		var failed = false;
		var errorListener:Dynamic->Void = null;
		errorListener = function(error:Dynamic) {
			failed = true;
			connection.removeListener("error", errorListener);
			onError(error);
		};
		connection.once("error", errorListener);
		try {
			connection.send(data);
		}
		catch (error:Dynamic) {
			connection.removeListener("error", errorListener);
			if (!failed) onError(error);
			return false;
		}
		if (!failed) connection.removeListener("error", errorListener);
		return !failed;
	}

	public static function getConnection(connectionId:String):Dynamic {
		return connections.get(connectionId);
	}

	public static function getPeer(peerId:String):Dynamic {
		return peers.get(peerId);
	}

	public static function peerDisconnect(peerId:String):Void {
		var peer = getPeer(peerId);
		if (peer == null) {
			trace("PeerNetwork: Peer ID is not available.");
			return;
		}
		peer.disconnect();
	}

	public static function peerReconnect(peerId:String):Void {
		var peer = getPeer(peerId);
		if (peer == null) {
			trace("PeerNetwork: Peer ID is not available.");
			return;
		}
		peer.reconnect();
	}

	public static function peerDestroy(peerId:String):Void {
		var peer = getPeer(peerId);
		if (peer == null) {
			trace("PeerNetwork: Peer ID is not available.");
			return;
		}
		peer.destroy();
	}

	public static function addPeerEventListener(peerId:String, event:String, listener:Dynamic->Void):Void {
		var peer = peers.get(peerId);
		if (peer == null) {
			trace("PeerNetwork: Peer ID is not available.");
			return;
		}
		peer.on(event, listener);
	}

	public static function removePeerEventListener(peerId:String, event:String, listener:Dynamic->Void):Void {
		var peer = peers.get(peerId);
		if (peer != null) peer.removeListener(event, listener);
	}

	public static function addPeerDataListener(peerId:String, listener:Dynamic->Dynamic->Void):Void {
		var listeners = peerDataListeners.get(peerId);
		if (listeners == null) {
			listeners = [];
			peerDataListeners.set(peerId, listeners);
		}
		listeners.push(listener);
		var peerConnections = PeerNetwork.peerConnections.get(peerId);
		if (peerConnections != null) for (connection in peerConnections.copy()) attachPeerDataListener(peerId, connection, listener);
	}

	public static function removePeerDataListener(peerId:String, listener:Dynamic->Dynamic->Void):Void {
		var listeners = peerDataListeners.get(peerId);
		if (listeners != null) {
			listeners.remove(listener);
			if (listeners.length == 0) peerDataListeners.remove(peerId);
		}
		for (binding in peerDataBindings.copy()) {
			if (binding.peerId == peerId && binding.listener == listener) {
				binding.connection.removeListener("data", binding.handler);
				peerDataBindings.remove(binding);
			}
		}
	}

	static function trackConnection(peerId:String, connection:Dynamic):Void {
		connections.set(connection.connectionId, connection);
		var peerConnections = PeerNetwork.peerConnections.get(peerId);
		if (peerConnections == null) {
			peerConnections = [];
			PeerNetwork.peerConnections.set(peerId, peerConnections);
		}
		peerConnections.push(connection);

		var remotePeerId:String = connection.peer;
		var peerInfo = PeerNetwork.peerConnectionInfo.get(peerId);
		if (peerInfo == null) {
			peerInfo = new Map();
			PeerNetwork.peerConnectionInfo.set(peerId, peerInfo);
		}
		var connectionsInfo = peerInfo.get(remotePeerId);
		if (connectionsInfo == null) {
			connectionsInfo = [];
			peerInfo.set(remotePeerId, connectionsInfo);
		}
		var info:PeerConnectionInfo = {
			connectionId: connection.connectionId,
			label: connection.label,
			metadata: connection.metadata,
			open: connection.open
		};
		connectionsInfo.push(info);
		connection.on("open", function() {
			info.open = true;
		});
		connection.on("close", function() {
			info.open = false;
		});

		var dataListeners = peerDataListeners.get(peerId);
		if (dataListeners != null) for (listener in dataListeners.copy()) attachPeerDataListener(peerId, connection, listener);
	}

	static function attachPeerDataListener(peerId:String, connection:Dynamic, listener:Dynamic->Dynamic->Void):Void {
		for (binding in peerDataBindings) {
			if (binding.peerId == peerId && binding.connection == connection && binding.listener == listener) return;
		}
		var handler:Dynamic->Void = function(data:Dynamic) listener(connection, data);
		peerDataBindings.push({
			peerId: peerId,
			connection: connection,
			listener: listener,
			handler: handler
		});
		connection.on("data", handler);
	}
}

private typedef PeerDataBinding = {
	var peerId:String;
	var connection:Dynamic;
	var listener:Dynamic->Dynamic->Void;
	var handler:Dynamic->Void;
}

typedef PeerConnectionInfo = {
	var connectionId:String;
	var label:String;
	var metadata:Dynamic;
	var open:Bool;
}
