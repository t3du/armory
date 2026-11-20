package armory.logicnode;

#if arm_ui
import zui.Zui;
#end

class ZuiElementStateNode extends LogicNode {
	public function new(tree: LogicTree) {
		super(tree);
	}

	#if arm_ui
	override function run(from: Int) {
		var ui = Zui.current;
		if (ui == null) return;
		// Snapshot before running branches: their UI chains may change Zui's
		// current element state. Run every matching branch before Next.
		var hovered = ui.isHovered;
		var started = ui.isStarted;
		var pushed = ui.isPushed;
		var released = ui.isReleased;
		if (hovered) runOutput(1); else runOutput(0);
		if (started) runOutput(2);
		if (pushed) runOutput(3);
		if (released) runOutput(4);
		runOutput(4);
	}
	#end
}
