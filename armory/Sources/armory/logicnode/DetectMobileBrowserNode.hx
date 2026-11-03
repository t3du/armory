package armory.logicnode;

class DetectMobileBrowserNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		#if kha_html5
		return kha.SystemImpl.mobile;
		#else
		return false;
		#end
	}
}