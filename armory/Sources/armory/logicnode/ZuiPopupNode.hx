package armory.logicnode;

#if arm_ui
import zui.Zui;
import armory.ui.Popup;
#end

class ZuiPopupNode extends LogicNode {
	public function new(tree: LogicTree) {
		super(tree);
	}

	#if arm_ui
	override function run(from: Int) {
		if (from == 1) {
			Popup.show = false;
			return;
		}

		var ui = Zui.current;
		if (ui == null) return;

		Popup.showCustom(new Zui(ui.ops), function(popupUi: Zui) {
			runOutput(0);
		}, inputs[2].get(), inputs[3].get(), inputs[4].get(), inputs[5].get());
	}
	#end
}
