package armory.logicnode;

#if arm_ui
import zui.Zui;
import zui.Zui.Handle;
#end

class ZuiCheckNode extends LogicNode {
	#if arm_ui
	var handle: Handle;
	var selected = false;
	#end

	public function new(tree: LogicTree) {
		super(tree);
	}

	#if arm_ui
	override function run(from: Int) {
		var ui = Zui.current;
		if (ui == null) return;

		if (handle == null) handle = new Handle({selected: inputs[2].get()});
		selected = ui.check(handle, inputs[1].get(), inputs[2].get());
		if (handle.changed) runOutput(0);
		runOutput(1);
	}

	override function get(from: Int): Dynamic {
		return selected;
	}
	#end
}
