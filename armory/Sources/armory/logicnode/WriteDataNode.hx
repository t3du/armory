package armory.logicnode;

class WriteDataNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var file: String = inputs[1].get();
		var data: Dynamic = inputs[2].get();

		#if kha_krom

		var bytes: haxe.io.Bytes = null;

		if (Std.isOfType(data, haxe.io.Bytes)) {
			bytes = cast data;
		}
		else if (data != null) {
			bytes = haxe.io.Bytes.ofData(data);
		}

		if (bytes != null) {
			var path = Krom.getFilesLocation() + "/" + file;
			Krom.fileSaveBytes(path, bytes.getData());
		}

		#elseif kha_html5

		if (data != null) {
			var jsData:Dynamic = data;

			var blob = new js.html.Blob(
				[jsData],
				{type: "application/octet-stream"}
			);

			var url = js.html.URL.createObjectURL(blob);

			var a = cast(
				js.Browser.document.createElement("a"),
				js.html.AnchorElement
			);

			a.href = url;
			a.download = file;
			a.click();

			js.html.URL.revokeObjectURL(url);
		}

		#end

		runOutput(0);
	}
}
