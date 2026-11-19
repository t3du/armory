package armory.logicnode;

#if arm_ui
import zui.Zui;
#end

class ZuiSeparatorNode extends LogicNode {
	public function new(tree: LogicTree) {
		super(tree);
	}

	#if arm_ui
	override function run(from: Int) {
		var ui = Zui.current;
		if (ui == null) return;

		ui.separator(inputs[1].get(), inputs[2].get());
		runOutput(0);
	}
	#end
}
