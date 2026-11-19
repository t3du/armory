package armory.logicnode;

#if arm_ui
import armory.ui.Ext;
import zui.Zui;
import zui.Zui.Handle;
#end

class ZuiListNode extends LogicNode {
	#if arm_ui
	var handle = new Handle();
	var items: Array<Dynamic> = [];
	var position = 0;
	var changed = false;
	#end

	public function new(tree: LogicTree) {
		super(tree);
	}

	#if arm_ui
	override function run(from: Int) {
		var ui = Zui.current;
		if (ui == null) return;

		items = inputs[1].get();
		if (items == null) items = [];
		if (inputs[3].get() && items.length > 0 && handle.nest(0).position < 0) handle.nest(0).position = 0;
		var before = items.copy();
		var previousPosition = position;
		var selected = Ext.list(ui, handle, items,
		{
			editable: inputs[2].get(),
			showRadio: inputs[3].get(),
			showAdd: inputs[4].get(),
			addLabel: inputs[5].get(),
			showRemove: inputs[6].get()
		});
		position = items.length == 0 ? -1 : selected;
		changed = items.length != before.length || position != previousPosition || (inputs[3].get() && items.length > 0 && handle.nest(0).changed);
		if (!changed) for (i in 0...items.length) if (items[i] != before[i]) { changed = true; break; }
		if (changed) runOutput(0);
		runOutput(1);
	}

	override function get(from: Int): Dynamic {
		return from == 2 ? items : position;
	}
	#end
}
