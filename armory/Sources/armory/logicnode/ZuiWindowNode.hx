package armory.logicnode;

#if arm_ui
import zui.Zui;
import zui.Zui.Handle;
#end

class ZuiWindowNode extends LogicNode {
	#if arm_ui
	var handle = new Handle();
	var cx: Float;
	var cy: Float;
	var scrollValue: Float;
	#end

	public function new(tree: LogicTree) {
		super(tree);
	}

	#if arm_ui
	override function run(from: Int) {
		var ui = Zui.current;
		if (ui == null) return;

		var x: Float = inputs[1].get();
		var y: Float = inputs[2].get();
		var w: Int = inputs[3].get();
		var h: Int = inputs[4].get();

		if (inputs[8].get()) handle.scrollOverride = false;
		var contentHeight = handle.lastMaxY - handle.scrollOffset;
		var maxScroll = -(contentHeight - h);
		if (!handle.scrollOverride) {
			var scroll: Float = Math.max(0, Math.min(1, inputs[7].get()));
			handle.scrollOffset = maxScroll < 0 ? maxScroll * scroll : 0;
			scrollValue = scroll;
		} else
			scrollValue = maxScroll < 0 ? handle.scrollOffset / maxScroll : 0;

		if (inputs[6].get()) {
			cx = kha.System.windowWidth() * x;
			cy = kha.System.windowHeight() * y;
			x = cx - w / 2;
			y = cy - h / 2;
			cx += handle.dragX;
			cy += handle.dragY;
		} else {
			cx = x + w / 2 + handle.dragX;
			cy = y + h / 2 + handle.dragY;
		}

		var isRedrawing = ui.window(handle, Std.int(x), Std.int(y), w, h, inputs[5].get());
		if (isRedrawing) runOutput(0);
		runOutput(1);
	}

	override function get(from: Int): Dynamic {
		return switch(from) {
			case 2: cx;
			case 3: cy;
			default: scrollValue;
			}
	}
	#end
}