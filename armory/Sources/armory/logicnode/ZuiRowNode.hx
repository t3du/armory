package armory.logicnode;

#if arm_ui
import zui.Zui;
#end

class ZuiRowNode extends LogicNode {
	public function new(tree: LogicTree) {
		super(tree);
	}

	#if arm_ui
	override function run(from: Int) {
		var ui = Zui.current;
		if (ui == null) return;

		var ratios: Array<Float> = inputs[1].get();
		if (ratios != null && ratios.length > 0) ui.row(ratios);
		runOutput(0);
	}
	#end
}
