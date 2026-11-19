package armory.logicnode;

import haxe.Timer;
import iron.math.Vec4;
import kha.Color;

#if arm_ui
import zui.Zui;
import zui.Themes.TTheme;
#end

class SetZuiThemeValuesNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	#if arm_ui
	override function run(from: Int) {
		var ui: Zui = inputs[1].get();

		if (ui != null && ui.t != null) {
			var t: TTheme = cast Reflect.copy(ui.t);
			ui.alwaysRedraw = true;
			setBgColors(t, vecToColor(inputs[2].get()));
			t.ACCENT_COL = vecToColor(inputs[3].get());
			t.ACCENT_HOVER_COL = vecToColor(inputs[4].get());
			t.ACCENT_SELECT_COL = vecToColor(inputs[5].get());
			t.BUTTON_COL = vecToColor(inputs[6].get());
			t.BUTTON_HOVER_COL = vecToColor(inputs[7].get());
			t.BUTTON_PRESSED_COL = vecToColor(inputs[8].get());
			t.BUTTON_TEXT_COL = vecToColor(inputs[9].get());
			t.TEXT_COL = vecToColor(inputs[10].get());
			t.LABEL_COL = vecToColor(inputs[11].get());
			ui.t = t;
			Timer.delay(function() { ui.alwaysRedraw = false; }, 1);
		}

		runOutput(0);
	}

	function vecToColor(v: Vec4): Color {
		return Color.fromFloats(v.x, v.y, v.z, v.w);
	}

	function setBgColors(t: TTheme, col: Color) {
		t.WINDOW_BG_COL = col;
		t.SEPARATOR_COL = col;
		t.CONTEXT_COL = col;
		t.PANEL_BG_COL = col;
	}
	#end
}