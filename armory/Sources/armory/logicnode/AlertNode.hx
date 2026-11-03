package armory.logicnode;

class AlertNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var msg: String = inputs[1].get();

		#if kha_krom
		Krom.sysCommand("powershell -command \"Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('" + msg + "', '" + Main.projectName + "')\"");
		#elseif kha_html5
		js.Browser.window.alert(msg);
		#end

		runOutput(0);
	}
}