package armory.logicnode;

#if arm_ui
import zui.Zui;
import zui.Zui.Align;
#end

class ZuiButtonNode extends LogicNode {
	public function new(tree: LogicTree) {
		super(tree);
	}

	#if arm_ui
	override function run(from: Int) {
		var ui = Zui.current;
		if (ui == null) return;

		var align: Align = switch (inputs[2].get()) {
			case 0: Align.Left;
			case 1: Align.Center;
			default: Align.Right;
		};

		var clicked = ui.button(inputs[1].get(), align, inputs[3].get());
		if (clicked) runOutput(0);
		runOutput(1);
	}
	#end
}
