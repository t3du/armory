package armory.logicnode;

#if arm_ui
import zui.Zui;
import zui.Zui.Handle;
import zui.Zui.Align;
#end

class ZuiSliderNode extends LogicNode {
	#if arm_ui
	var handle: Handle;
	#end

	public function new(tree: LogicTree) {
		super(tree);
	}

	#if arm_ui
	override function run(from: Int) {
		var ui = Zui.current;
		if (ui == null) return;

		if (handle == null) handle = new Handle({value: inputs[4].get()});
		var align: Align = switch (inputs[8].get()) {
			case 0: Align.Left;
			case 1: Align.Center;
			default: Align.Right;
		};
		handle.value = ui.slider(handle, inputs[1].get(), inputs[2].get(), inputs[3].get(), inputs[5].get(), inputs[6].get(), inputs[7].get(), align, inputs[9].get());
		if (handle.changed) runOutput(0);
		runOutput(1);
	}

	override function get(from: Int): Dynamic {
		return handle == null ? inputs[4].get() : handle.value;
	}
	#end
}
