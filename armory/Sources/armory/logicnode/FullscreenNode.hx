package armory.logicnode;

class FullscreenNode extends LogicNode {

	private static var kromFullscreen: Bool = false;
	private static var initialized: Bool = false;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var fullscreen: Bool = inputs[1].get();

		#if kha_krom
		if (!initialized) {
			kromFullscreen = kha.Window.get(0).mode == kha.WindowMode.Fullscreen;
			initialized = true;
		}
		if (fullscreen != kromFullscreen) {
			Krom.sysCommand("powershell -command \"$wshell = New-Object -ComObject wscript.shell; $wshell.SendKeys('%{ENTER}')\"");
			kromFullscreen = fullscreen;
		}
		#elseif kha_html5
		if (fullscreen) {
			js.Browser.document.documentElement.requestFullscreen();
		}
		else {
			if (js.Browser.document.exitFullscreen != null) {
				js.Browser.document.exitFullscreen();
			}
		}
		#end

		runOutput(0);
	}
}