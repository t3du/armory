package armory.logicnode;

import armory.renderpath.RenderToTexture;
#if arm_ui
import zui.Zui;
#end

class ZuiContextNode extends LogicNode {
	#if arm_ui
	var ui: Zui;
	var loading = false;
	var popupActiveLastFrame = false;
	var fontSize = 0;
	var scaleFactor = 1.0;
	#end

	public function new(tree: LogicTree) {
		super(tree);
		#if arm_ui
		tree.notifyOnRemove(function() {
			if (ui != null) ui.remove();
		});
		#end
	}

	#if arm_ui
	override function run(from: Int) {
		var g = RenderToTexture.g;
		if (g == null) return;
		if (ui == null) {
			if (!loading) initializeUi();
			return;
		}

		var oldAlwaysRedraw = ui.alwaysRedraw;
		ui.alwaysRedraw = oldAlwaysRedraw || armory.ui.Popup.show || popupActiveLastFrame;
		// Zui owns the frame and may begin the graphics context while drawing
		// its windows, so suspend the render callback's active context first.
		g.end();
		ui.begin(g);
		runOutput(0);
		ui.end();
		ui.alwaysRedraw = oldAlwaysRedraw;

		if (armory.ui.Popup.show) {
			armory.ui.Popup.update();
			if (armory.ui.Popup.show) armory.ui.Popup.render(g);
		}
		popupActiveLastFrame = armory.ui.Popup.show;
		g.begin(false);
	}

	override function get(from: Int): Dynamic {
		return ui;
	}

	function initializeUi() {
		loading = true;
		var fontName: String = inputs[1].get();
		if (fontName == null || fontName == "") fontName = "font_default.ttf";
		scaleFactor = inputs[2].get();
		if (scaleFactor <= 0) scaleFactor = 1.0;
		fontSize = inputs[3].get();
		var themeName: String = inputs[4].get();
		iron.data.Data.getFont(fontName, function(font: kha.Font) {
			iron.data.Data.getImage("color_wheel.png", function(colorWheel: kha.Image) {
				iron.data.Data.getImage("black_white_gradient.png", function(gradient: kha.Image) {
					if (themeName == null || StringTools.trim(themeName) == "") {
						createUi(font, null, colorWheel, gradient);
					}
					else {
						iron.data.Data.getBlob("_themes.json", function(blob: kha.Blob) {
							var themes: Array<Dynamic> = [];
							if (blob != null && @:privateAccess blob.get_length() > 0) {
								themes = cast haxe.Json.parse(blob.toString());
							}
							var selectedTheme: Dynamic = null;
							for (candidate in themes) {
								if (Reflect.field(candidate, "NAME") == themeName) {
									selectedTheme = candidate;
									break;
								}
							}
							createUi(font, selectedTheme, colorWheel, gradient);
						});
					}
				});
			});
		});
	}

	function createUi(font: kha.Font, selectedTheme: Dynamic, colorWheel: kha.Image, gradient: kha.Image) {
		var theme: zui.Themes.TTheme = selectedTheme == null ? null : cast Reflect.copy(selectedTheme);
		if (fontSize != 0) {
			if (theme == null) theme = Reflect.copy(zui.Themes.dark);
			theme.FONT_SIZE = fontSize;
		}
		ui = new Zui({font: font, theme: theme, scaleFactor: scaleFactor, color_wheel: colorWheel, black_white_gradient: gradient});
	}
	#end
}
