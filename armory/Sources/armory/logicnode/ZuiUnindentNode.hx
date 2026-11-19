package armory.logicnode;

#if arm_ui
import zui.Zui;
#end

class ZuiUnindentNode extends LogicNode {
	public function new(tree: LogicTree) {
		super(tree);
	}

	#if arm_ui
	override function run(from: Int) {
		var ui = Zui.current;
		if (ui == null) return;

		ui.unindent(inputs[1].get());
		runOutput(0);
	}
	#end
}
