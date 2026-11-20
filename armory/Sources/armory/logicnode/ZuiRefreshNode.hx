package armory.logicnode;

import haxe.Timer;

#if arm_ui
import zui.Zui;
#end

class ZuiRefreshNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	#if arm_ui
	override function run(from: Int) {
		var ui: Zui = inputs[1].get();

		if (ui != null){
			ui.alwaysRedraw = true;
			Timer.delay(function() { ui.alwaysRedraw = false; }, 1);
		}

		runOutput(0);
	}
	#end
}