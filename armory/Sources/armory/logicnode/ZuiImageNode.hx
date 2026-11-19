package armory.logicnode;

import kha.Color;
import kha.Image;
import iron.math.Vec4;
import iron.data.Data;

#if arm_ui
import zui.Zui;
#end

class ZuiImageNode extends LogicNode {
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

		var colorVec: Vec4 = inputs[2].get();
		var height: Float = inputs[3].get();
		var sX: Int = inputs[4].get();
		var sY: Int = inputs[5].get();
		var sWidth: Int = inputs[6].get();
		var sHeight: Int = inputs[7].get();

		var img: Image = Data.cachedImages.get(path);
		if (img == null) {
			Data.getImage(path, function(loaded: Image) {
				img = loaded;
			});
		}

		if (img != null)
			ui.image(img, Color.fromFloats(colorVec.x, colorVec.y, colorVec.z, colorVec.w), height, sX, sY, sWidth, sHeight);

		runOutput(0);
	}
	#end
}