package armory.network;

class PeerNetwork {
	public static var peers:Map<String, Dynamic> = new Map();
	public static var connections:Map<String, Dynamic> = new Map();
	public static var peerConnections:Map<String, Array<Dynamic>> = new Map();
	public static var peerConnectionInfo:Map<String, Map<String, Array<PeerConnectionInfo>>> = new Map();
	public static var calls:Map<String, Dynamic> = new Map();
	public static var peerCalls:Map<String, Array<Dynamic>> = new Map();
	public static var peerCallInfo:Map<String, Map<String, Array<PeerCallInfo>>> = new Map();
	static var callStreams:Map<String, Dynamic> = new Map();
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
		peerId.on("call", function(call:Dynamic) {
			trackCall(peerId.id, call);
		});
	}

	public static function peerCall(peerIdFrom:String, peerIdTo:String, videoSource:Int, audio:Bool, metadata:Dynamic, onReady:String->Void, onError:Dynamic->Void):Void {
		var peer = peers.get(peerIdFrom);
		if (peer == null) {
			onError("PeerNetwork: Peer ID From is not available.");
			return;
		}
		if (peerIdTo == null || peerIdTo == "") {
			onError("PeerNetwork: Peer ID To is required.");
			return;
		}
		if (peerIdFrom == peerIdTo) {
			onError("PeerNetwork: A peer cannot call itself.");
			return;
		}
		if (!audio && videoSource == 0) {
			onError("PeerNetwork: Enable audio or select a video source to start a call.");
			return;
		}
		requestCallMedia(videoSource, audio, false, function(stream:Dynamic) {
			var call:Dynamic;
			try {
				call = peer.call(peerIdTo, stream, {metadata: metadata});
			}
			catch (error:Dynamic) {
				stopMediaStream(stream);
				onError(error);
				return;
			}
			if (call == null) {
				stopMediaStream(stream);
				onError("PeerNetwork: PeerJS did not create a media call.");
				return;
			}
			trackCall(peerIdFrom, call);
			callStreams.set(call.connectionId, stream);
			call.emit("localStream", stream);
			call.on("error", function(error:Dynamic) onError(error));
			if (onReady != null) onReady(call.connectionId);
		}, onError);
	}

	public static function peerCallAnswer(callId:String, videoSource:Int, audio:Bool, onReady:Void->Void, onError:Dynamic->Void):Void {
		var call = calls.get(callId);
		if (call == null) {
			onError("PeerNetwork: Call ID is not available.");
			return;
		}
		requestCallMedia(videoSource, audio, true, function(stream:Dynamic) {
			if (calls.get(callId) != call) {
				stopMediaStream(stream);
				onError("PeerNetwork: Call closed before it could be answered.");
				return;
			}
			try {
				call.on("error", function(error:Dynamic) onError(error));
				call.answer(stream);
				if (stream != null) {
					callStreams.set(callId, stream);
					call.emit("localStream", stream);
				}
				updatePeerCallInfoOpen(callId, call.open);
				if (onReady != null) onReady();
			}
			catch (error:Dynamic) {
				stopMediaStream(stream);
				onError(error);
			}
		}, onError);
	}

	public static function peerCallClose(callId:String, onError:Dynamic->Void):Bool {
		var call = calls.get(callId);
		if (call == null) {
			onError("PeerNetwork: Call ID is not available.");
			return false;
		}
		try {
			call.close();
			if (calls.get(callId) == call) {
				calls.remove(callId);
				stopMediaStream(callStreams.get(callId));
				callStreams.remove(callId);
			}
			updatePeerCallInfoOpen(callId, call.open);
			return true;
		}
		catch (error:Dynamic) {
			onError(error);
			return false;
		}
	}

	static function requestCallMedia(videoSource:Int, audio:Bool, allowEmpty:Bool, onReady:Dynamic->Void, onError:Dynamic->Void):Void {
		if (videoSource < 0 || videoSource > 2) {
			onError("PeerNetwork: Video input must be 0 (none), 1 (camera), or 2 (screen).");
			return;
		}
		if (videoSource == 0 && !audio) {
			if (allowEmpty) onReady(null);
			else onError("PeerNetwork: Enable audio or select a video source to start a call.");
			return;
		}
		var mediaDevices:Dynamic = js.Syntax.code("navigator.mediaDevices");
		if (mediaDevices == null) {
			onError("PeerNetwork: Browser media capture is not available.");
			return;
		}
		if (videoSource == 2) {
			var screenPromise:Dynamic;
			try {
				screenPromise = mediaDevices.getDisplayMedia({video: true, audio: false});
			}
			catch (error:Dynamic) {
				onError(error);
				return;
			}
			screenPromise.then(function(screenStream:Dynamic) {
				if (!audio) {
					onReady(screenStream);
					return;
				}
				var audioPromise:Dynamic;
				try {
					audioPromise = mediaDevices.getUserMedia({audio: true, video: false});
				}
				catch (error:Dynamic) {
					stopMediaStream(screenStream);
					onError(error);
					return;
				}
				audioPromise.then(function(audioStream:Dynamic) {
					try {
						var combined:Dynamic = js.Syntax.code("new MediaStream()");
						var screenTracks:Dynamic = screenStream.getTracks();
						for (i in 0...screenTracks.length) combined.addTrack(screenTracks[i]);
						var audioTracks:Dynamic = audioStream.getAudioTracks();
						for (i in 0...audioTracks.length) combined.addTrack(audioTracks[i]);
						onReady(combined);
					}
					catch (error:Dynamic) {
						stopMediaStream(screenStream);
						stopMediaStream(audioStream);
						onError(error);
					}
				}, function(error:Dynamic) {
					stopMediaStream(screenStream);
					onError(error);
				});
			}, onError);
			return;
		}

		var constraints:Dynamic = {
			audio: audio,
			video: videoSource == 1
		};
		var promise:Dynamic;
		try {
			promise = mediaDevices.getUserMedia(constraints);
		}
		catch (error:Dynamic) {
			onError(error);
			return;
		}
		promise.then(onReady, onError);
	}

	static function stopMediaStream(stream:Dynamic):Void {
		if (stream == null) return;
		var tracks:Dynamic = stream.getTracks();
		for (i in 0...tracks.length) tracks[i].stop();
	}

	public static function getCall(callId:String):Dynamic {
		return calls.get(callId);
	}

	static function trackCall(localPeerId:String, call:Dynamic):Void {
		var callId:String = call.connectionId;
		calls.set(callId, call);
		var callsForPeer = peerCalls.get(localPeerId);
		if (callsForPeer == null) {
			callsForPeer = [];
			peerCalls.set(localPeerId, callsForPeer);
		}
		callsForPeer.push(call);

		var callsByRemotePeer = peerCallInfo.get(localPeerId);
		if (callsByRemotePeer == null) {
			callsByRemotePeer = new Map();
			peerCallInfo.set(localPeerId, callsByRemotePeer);
		}
		var callsWithRemotePeer = callsByRemotePeer.get(call.peer);
		if (callsWithRemotePeer == null) {
			callsWithRemotePeer = [];
			callsByRemotePeer.set(call.peer, callsWithRemotePeer);
		}
		var info:PeerCallInfo = {
			callId: callId,
			metadata: call.metadata,
			open: call.open
		};
		callsWithRemotePeer.push(info);
		call.on("stream", function(_stream:Dynamic) {
			updatePeerCallInfoOpen(callId, call.open);
		});
		call.on("iceStateChanged", function(state:String) {
			if (state == "connected" || state == "completed") updatePeerCallInfoOpen(callId, true);
			else if (state == "closed") updatePeerCallInfoOpen(callId, false);
		});
		call.on("close", function() {
			updatePeerCallInfoOpen(callId, false);
			if (calls.get(callId) == call) calls.remove(callId);
			stopMediaStream(callStreams.get(callId));
			callStreams.remove(callId);
		});
	}

	static function updatePeerCallInfoOpen(callId:String, open:Bool):Void {
		for (localPeerId in peerCallInfo.keys()) {
			var callsByRemotePeer = peerCallInfo.get(localPeerId);
			for (remotePeerId in callsByRemotePeer.keys()) {
				for (info in callsByRemotePeer.get(remotePeerId)) {
					if (info.callId == callId) {
						var call = calls.get(callId);
						info.open = call != null ? call.open : open;
						return;
					}
				}
			}
		}
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

	public static function connectionSend(connectionId:String, data:Dynamic, onError:Dynamic->Void):Bool {
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

typedef PeerCallInfo = {
	var callId:String;
	var metadata:Dynamic;
	var open:Bool;
}
