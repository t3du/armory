package armory.logicnode;

import iron.math.Vec4;
import kha.Color;

#if arm_ui
import zui.Zui;
import zui.Zui.Handle;
#end

class ZuiTabNode extends LogicNode {
	#if arm_ui
	var handle: Handle;
	var position = -1;
	var lastPosition: Null<Int> = null;
	#end

	public function new(tree: LogicTree) {
		super(tree);
	}

	#if arm_ui
	override function run(from: Int) {
		var ui = Zui.current;
		if (ui == null) return;

		var tabs: Array<String> = inputs[1].get();
		var colors: Array<Vec4> = inputs[2].get();
		if (tabs == null || tabs.length == 0) {
			position = -1;
			return;
		}

		if (handle == null) handle = new Handle({position: inputs[4].get()});

		for (i in 0...tabs.length) 
			if (colors != null && colors[i] != null)
				ui.tab(handle, tabs[i], inputs[3].get(), Color.fromFloats(colors[i].x, colors[i].y, colors[i].z, colors[i].w));
			else
				ui.tab(handle, tabs[i], inputs[3].get());
		position = handle.position;
		var selectionChanged = lastPosition != null && position != lastPosition;
		lastPosition = position;
		if (position >= 0 && position < tabs.length) runOutput(0);
		if (selectionChanged) runOutput(1);
		runOutput(2);
	}

	override function get(from: Int): Dynamic {
		return position;
	}
	#end
}
