package armory.network;

class PeerNetwork {
	public static function peerStart(?id:String, ?onReady:String->Void):Void {
		if (js.Syntax.code("window.peerjs") == null) {
			iron.data.Data.getBlob("peerjs.min.js", function(blob:kha.Blob) {
				var script = js.Browser.document.createScriptElement();
				script.text = blob.bytes.toString();
				js.Browser.document.head.appendChild(script);
				peerStart(id, onReady);
			});
			return;
		}
		var peerId:Dynamic = id == ""
			? js.Syntax.code("new window.peerjs.Peer()")
			: js.Syntax.code("new window.peerjs.Peer({0})", id);
		peerId.on("open", function(Id:String) {
			if (onReady != null) onReady(Id);
		});
	}
}
