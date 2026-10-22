package armory.logicnode;

class CopyToClipboardNode extends LogicNode {

	public function new(tree:LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var text: String = inputs[1].get();
		#if kha_krom
		js.Syntax.code("Krom.copyToClipboard({0})", text);
		#elseif kha_html5
		if (js.Syntax.code("navigator.clipboard && window.isSecureContext")) {
			js.Syntax.code("navigator.clipboard.writeText({0})", text);
		}
		#end
		runOutput(0);
	}
}