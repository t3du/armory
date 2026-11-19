package armory.logicnode;

#if arm_ui
import zui.Zui;
import zui.Zui.Handle;
import zui.Zui.Align;
import zui.Ext;
#end

class ZuiInlineRadioNode extends LogicNode {
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

		var texts: String = inputs[1].get();
		if (texts == null || texts.length == 0) {
			position = -1;
			handle.position = position;
			runOutput(0);
			return;
		}

		var align: Align = switch (inputs[2].get()) {
			case 0: Align.Left;
			case 1: Align.Center;
			default: Align.Right;
		};
		
		if (handle == null) handle = new Handle({position: inputs[3].get()});
		position = Ext.inlineRadio(ui, handle, inputs[1].get(), align);
		if (handle.changed) runOutput(0);
		runOutput(1);
	}

	override function get(from: Int): Dynamic {
		return position;
	}
	#end
}
