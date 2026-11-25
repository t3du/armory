package armory.logicnode;

#if arm_ui
import zui.Zui;
import armory.ui.Popup;
#end

class ZuiPopupMessageNode extends LogicNode {
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

		Popup.showMessage(new Zui(ui.ops), inputs[2].get(), inputs[3].get());
	}
	#end
}
