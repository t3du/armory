package armory.logicnode;

class LoadUrlNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var url: String = inputs[1].get();
		if (url == null) url = "";

		#if kha_krom
		url = url.split("\"").join("\\\"");
		var res = Krom.sysCommand("cmd /c start " + url);
		if (res == 0) {
			runOutput(0);
		}
		else {
			runOutput(1);
		}
		#elseif kha_html5
		if (inputs[2].get()){
			var window = inputs[3].get() ? js.Browser.window.open(url, "_blank", "width="+inputs[4].get()+",height="+inputs[5].get()+",left="+inputs[6].get()+",top="+inputs[7].get())
			: js.Browser.window.open(url, "_blank");
			
			if(window != null)
				runOutput(0);
			else
				runOutput(1);
		}
		else {
			js.Browser.window.open(url, "_self");
			runOutput(0);
		}
		#end
	}
}