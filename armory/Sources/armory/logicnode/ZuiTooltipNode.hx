package armory.logicnode;

#if arm_ui
import zui.Zui;
#end

class ZuiTooltipNode extends LogicNode {
	public function new(tree: LogicTree) {
		super(tree);
	}

	#if arm_ui
	override function run(from: Int) {
		var ui = Zui.current;
		if (ui == null) return;
		
		ui.tooltip(inputs[1].get());
		runOutput(0);
	}
	#end
}
