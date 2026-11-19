package armory.logicnode;

#if arm_ui
import zui.Zui;
import zui.Zui.Handle;
#end

class ZuiPanelNode extends LogicNode {
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

		if (handle == null) handle = new Handle({selected: inputs[5].get()});
		selected = ui.panel(handle, inputs[1].get(), inputs[2].get(), inputs[3].get(), inputs[4].get());
		var panelChanged = handle.changed;
		if (selected) {
			ui.indent();
			runOutput(0);
			ui.unindent();
		}

		if (panelChanged){ handle.changed = false; runOutput(1); }
		runOutput(2);
	}

	override function get(from: Int): Dynamic {
		return selected;
	}
	#end
}
