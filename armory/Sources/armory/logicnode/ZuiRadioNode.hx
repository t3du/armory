package armory.logicnode;

#if arm_ui
import zui.Zui;
import zui.Zui.Handle;
#end

class ZuiRadioNode extends LogicNode {
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
		var labels: Array<String> = inputs[2].get();
		if (texts == null || texts.length == 0) {
			position = -1;
			handle.position = position;
			runOutput(0);
			return;
		}

		if (handle == null) handle = new Handle({position: inputs[3].get()});
		if (handle.position < 0 || handle.position >= texts.length) handle.position = 0;
		for (i in 0...texts.length) {
			if (labels != null && labels[i] != '')
				ui.radio(handle, i, texts[i], labels[i]);
			else
				ui.radio(handle, i, texts[i]);
		}
		position = handle.position;
		if (handle.changed) runOutput(0);
		runOutput(1);
	}

	override function get(from: Int): Dynamic {
		return position;
	}
	#end
}
