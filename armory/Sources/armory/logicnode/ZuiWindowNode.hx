package armory.logicnode;

#if arm_ui
import zui.Zui;
import zui.Zui.Handle;
#end

class ZuiWindowNode extends LogicNode {
	#if arm_ui
	var handle = new Handle();
	#end

	public function new(tree: LogicTree) {
		super(tree);
	}

	#if arm_ui
	override function run(from: Int) {
		var ui = Zui.current;
		if (ui == null) return;

		var isRedrawing = ui.window(handle, inputs[1].get(), inputs[2].get(), inputs[3].get(), inputs[4].get(), inputs[5].get());
		if (isRedrawing) runOutput(0);
		runOutput(1);
	}
	#end
}
