package armory.logicnode;

import kha.Image;
import iron.data.Data;

#if arm_ui
import zui.Zui;
#end

class ZuiTooltipImageNode extends LogicNode {
	public function new(tree: LogicTree) {
		super(tree);
	}

	#if arm_ui
	override function run(from: Int) {
		var ui = Zui.current;
		if (ui == null) return;

		var path: String = inputs[1].get();
		if (path == null || path == "") {
			runOutput(0);
			return;
		}

		var img: Image = Data.cachedImages.get(path);
		if (img == null) {
			Data.getImage(path, function(loaded: Image) {
				img = loaded;
			});
		}

		var maxWidth: Int = inputs[2].get();
		
		if (maxWidth > 0)
			ui.tooltipImage(img, maxWidth);
		else
			ui.tooltipImage(img);
		runOutput(0);
	}
	#end
}
