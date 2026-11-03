package armory.logicnode;

class ConfirmNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var msg: String = inputs[1].get();
		var answer: Bool = false;

		#if kha_krom
		var save = Krom.getFilesLocation() + "/confirm.txt";
		var psCommand = "powershell -command \"Add-Type -AssemblyName System.Windows.Forms; $res = [System.Windows.Forms.MessageBox]::Show('" + msg + "', '" + Main.projectName + "', [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question); if ($res -eq [System.Windows.Forms.DialogResult]::Yes) { [System.IO.File]::WriteAllText('" + save + "', 'true') } else { [System.IO.File]::WriteAllText('" + save + "', 'false') }\"";
		Krom.sysCommand(psCommand);
		var bytes = Krom.loadBlob("confirm.txt");
		if (bytes != null) {
			answer = haxe.io.Bytes.ofData(bytes).toString() == "true";
		}
		#elseif kha_html5
		answer = js.Browser.window.confirm(msg);
		#end

		if (answer) {
			runOutput(0);
		}
		else {
			runOutput(1);
		}
	}
}