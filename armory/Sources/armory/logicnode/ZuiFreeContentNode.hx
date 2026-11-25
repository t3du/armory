package armory.logicnode;

import armory.renderpath.RenderToTexture;
import kha.Color;
import iron.math.Vec4;

#if arm_ui
import zui.Zui;
#end

@:access(zui.Zui)
class ZuiFreeContentNode extends LogicNode {
	#if arm_ui
	var cx: Float = 0;
	var cy: Float = 0;
	var contentH: Float = 0;
	#end

	public function new(tree: LogicTree) {
		super(tree);
	}

	#if arm_ui
	override function run(from: Int) {
		var ui: Zui = inputs[1].get();
		if (ui == null) ui = Zui.current;
		if (ui == null) return;

		var g = RenderToTexture.g;
		if (g == null) return;

		var x: Float = inputs[2].get();
		var y: Float = inputs[3].get();
		var w: Int = inputs[4].get();
		var bgColorVec: Vec4 = inputs[5].get();
		var margin: Float = inputs[6].get();

		if (inputs[7].get()) {
			cx = kha.System.windowWidth() * x;
			cy = kha.System.windowHeight() * y;
			x = cx - w / 2;
			y = cy - contentH / 2;
		} else {
			cx = x + w / 2;
			cy = y + contentH / 2;
		}

		// Save the full Zui state so nested free-contexts and sibling
		// windows are not disturbed.
		var prevCurrent = Zui.current;
		var prevG = ui.g;
		var prevGlobalG = ui.globalG;
		var prevWindow = ui.currentWindow;
		var prevWinX = ui._windowX;
		var prevWinY = ui._windowY;
		var prevWinW = ui._windowW;
		var prevX = ui._x;
		var prevY = ui._y;
		var prevW = ui._w;

		// Set up a window-less drawing region, similar to Zui.beginRegion().
		// This lets child widgets (text, button, slider…) render at an
		// arbitrary screen position without requiring a Zui window.
		Zui.current = ui;
		ui.globalG = g;
		ui.g = g;
		ui.currentWindow = null;
		ui._windowX = 0;
		ui._windowY = 0;
		ui._windowW = w;
		ui._x = x;
		ui._y = y;
		ui._w = w;

		if (bgColorVec.w != 0) {
			var prevColor = g.color;
			g.color = Color.fromFloats(bgColorVec.x, bgColorVec.y, bgColorVec.z, bgColorVec.w);
			g.fillRect(x - margin, y - margin, w + margin * 2, contentH + margin * 2);
			g.color = prevColor;
		}

		runOutput(0);
		contentH = ui._y - y;

		// Restore previous state.
		Zui.current = prevCurrent;
		ui.g = prevG;
		ui.globalG = prevGlobalG;
		ui.currentWindow = prevWindow;
		ui._windowX = prevWinX;
		ui._windowY = prevWinY;
		ui._windowW = prevWinW;
		ui._x = prevX;
		ui._y = prevY;
		ui._w = prevW;
	}

	override function get(from: Int): Dynamic {
		return switch (from) {
			case 1: cx;
			case 2: cy;
			default: contentH;
		}
	}
	#end
}
