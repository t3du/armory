package armory.logicnode;

import armory.network.PeerNetwork;

class CallEventNode extends LogicNode {
	public var property0:String;
	var callId = "";
	var streamFrom:Dynamic;
	var streamTo:Dynamic;
	var error:Dynamic;
	var call:Dynamic;
	var callEventListener:Dynamic->Void;
	var streamFromListener:Dynamic->Void;
	var streamToListener:Dynamic->Void;
	var listenedEvent:String;

	public function new(tree:LogicTree) {
		super(tree);
		tree.notifyOnRemove(onRemove);
	}

	override function run(from:Int):Void {
		removeListeners();
		streamFrom = null;
		streamTo = null;
		error = null;
		callId = inputs[1].get();
		call = PeerNetwork.getCall(callId);
		if (call == null) {
			trace("CallEventNode: Call ID is not available.");
			return;
		}
		if (property0 == "stream") {
			streamFrom = call.localStream;
			streamTo = call.remoteStream;
			streamFromListener = function(value:Dynamic) {
				streamFrom = value;
				runOutput(0);
			};
			streamToListener = function(value:Dynamic) {
				streamTo = value;
				runOutput(0);
			};
			call.on("localStream", streamFromListener);
			call.on("stream", streamToListener);
			if (streamFrom != null || streamTo != null) runOutput(0);
		}
		else {
			callEventListener = function(value:Dynamic) {
				if (property0 == "error") error = value;
				runOutput(0);
			};
			call.on(property0, callEventListener);
			listenedEvent = property0;
		}
	}

	function onRemove():Void {
		removeListeners();
	}

	function removeListeners():Void {
		if (call != null) {
			if (streamFromListener != null) call.removeListener("localStream", streamFromListener);
			if (streamToListener != null) call.removeListener("stream", streamToListener);
			if (callEventListener != null && listenedEvent != null) call.removeListener(listenedEvent, callEventListener);
		}
		callEventListener = null;
		streamFromListener = null;
		streamToListener = null;
		listenedEvent = null;
		call = null;
	}

	override function get(from:Int):Dynamic {
		return switch (property0) {
			case "stream":
				from == 1 ? streamFrom : streamTo;
			case "error": error;
			default: null;
		};
	}
}
