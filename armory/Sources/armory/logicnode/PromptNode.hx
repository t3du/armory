package armory.logicnode;

class PromptNode extends LogicNode {

	var input: String = null;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var msg: String = inputs[1].get();
		var def: String = inputs[2].get();

		#if kha_krom
		var save = Krom.getFilesLocation() + "/prompt.txt";
		var psCommand = "powershell -command \"Add-Type -AssemblyName Microsoft.VisualBasic; $res = [Microsoft.VisualBasic.Interaction]::InputBox('" + msg + "', '" + Main.projectName + "', '" + def + "'); [System.IO.File]::WriteAllText('" + save + "', $res)\"";
		Krom.sysCommand(psCommand);
		var bytes = Krom.loadBlob("prompt.txt");
		if (bytes != null)
			input = haxe.io.Bytes.ofData(bytes).toString();
		#elseif kha_html5
		input = js.Browser.window.prompt(msg, def);
		#end

		if (input != null){
			if (input == '') input = def;
			runOutput(0);
		} else 
			runOutput(1);
	}

	override function get(from: Int): Dynamic {
		return input;
	}
}