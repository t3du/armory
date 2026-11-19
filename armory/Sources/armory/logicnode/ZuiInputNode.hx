package armory.logicnode;

#if arm_ui
import zui.Zui;
import zui.Zui.Handle;
import zui.Zui.Align;
import zui.Ext;
#end

class ZuiInputNode extends LogicNode {
	#if arm_ui
	var handle: Handle;
	var value: Dynamic;
	#end
	public var property0: String = "Text";

	public function new(tree: LogicTree) {
		super(tree);
	}

	#if arm_ui
	override function run(from: Int) {
		var ui = Zui.current;
		if (ui == null) return;

		if (handle == null) {
			handle = new Handle({text: inputs[4].get()});
			value = handle.text;
		}

		var align: Align = switch (inputs[2].get()) {
			case 0: Align.Left;
			case 1: Align.Center;
			default: Align.Right;
		};

		var label: String = inputs[1].get();
		var editable: Bool = inputs[3].get();
		switch (property0) {
			case "Text":
				value = ui.textInput(handle, label, align, editable, true); //liveUpdate
			case "Text Area":
				value = Ext.textArea(ui, handle, align, editable, label, true);
			case "Float":
				if (editable) value = Ext.floatInput(ui, handle, label, inputs[5].get());
				else {
					handle.text = Std.string(handle.value);
					ui.textInput(handle, label, align, false);
					value = handle.value;
				}
			case "Integer":
				if (editable) handle.value = Math.round(Ext.floatInput(ui, handle, label));
				else {
					handle.text = Std.string(Std.int(handle.value));
					ui.textInput(handle, label, align, false);
				}
				value = Std.int(handle.value);
		}

		if (handle.changed) runOutput(0);
		runOutput(1);
	}

	override function get(from: Int): Dynamic {
		return value;
	}
	#end
}
