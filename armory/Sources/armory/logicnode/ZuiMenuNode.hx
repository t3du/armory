package armory.logicnode;

#if arm_ui
import zui.Zui;
import zui.Ext;
#end

class ZuiMenuNode extends LogicNode {
	#if arm_ui
	var position = -1;
	#end

	public function new(tree: LogicTree) {
		super(tree);
	}

	#if arm_ui
	override function run(from: Int) {
		var ui = Zui.current;
		if (ui == null) return;

		var items: Array<String> = inputs[1].get();
		var changed = false;
		Ext.beginMenu(ui);
		if (items != null && items.length > 0) {
			var widths: Array<Float> = [];
			for (_ in items) widths.push(-1.0);
			ui.row(widths);
			for (i in 0...items.length) {
				if (Ext.menuButton(ui, items[i])) {
					position = i;
					changed = true;
				}
			}
		}
		Ext.endMenu(ui);
		if (changed) runOutput(0);
		runOutput(1);
	}

	override function get(from: Int): Dynamic {
		return position;
	}
	#end
}
