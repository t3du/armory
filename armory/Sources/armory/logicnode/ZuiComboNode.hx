package armory.logicnode;

#if arm_ui
import zui.Zui;
import zui.Zui.Handle;
import zui.Zui.Align;
#end

class ZuiComboNode extends LogicNode {
	#if arm_ui
	var handle: Handle;
	var position = 0;
	#end

	public function new(tree: LogicTree) {
		super(tree);
	}

	#if arm_ui
	override function run(from: Int) {
		var ui = Zui.current;
		if (ui == null) return;

		var texts: Array<String> = inputs[1].get();
		if (texts == null || texts.length == 0) {
			position = -1;
			runOutput(0);
			return;
		}

		var align: Align = switch (inputs[4].get()) {
			case 0: Align.Left;
			case 1: Align.Center;
			default: Align.Right;
		};

		if (handle == null) handle = new Handle({position: inputs[6].get()});
		if (handle.position < 0 || handle.position >= texts.length) handle.position = 0;
		position = ui.combo(handle, texts, inputs[2].get(), inputs[3].get(), align, inputs[5].get());

		if (handle.changed) runOutput(0);
		runOutput(1);
	}

	override function get(from: Int): Dynamic {
		return position;
	}
	#end
}
