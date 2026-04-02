package armory.logicnode;

import iron.math.Vec4;
import iron.object.Object;
import iron.data.MaterialData;
import kha.Color;
import kha.Image;
import armory.trait.internal.UniformsManager;

class GetImageColorNode extends LogicNode {

	public var property0: String;
	var internalRT: Image = null;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var x: Int;
		var y: Int;
		var sourceImg: Image = null;

		if (property0 == 'Image') {
			var imageName = inputs[0].get();
			x = inputs[1].get();
			y = inputs[2].get();
			iron.data.Data.getImage(imageName, (image: Image) -> { sourceImg = image; });
		} 
		else if (property0 == 'RenderTarget') {
			var obj: Object = inputs[0].get();
			var mat: MaterialData = inputs[1].get();
			var link: String = inputs[2].get();
			x = inputs[3].get();
			y = inputs[4].get();
			
			sourceImg = UniformsManager.textureLink(obj, mat, link);
		}
		else {
			x = inputs[0].get();
			y = inputs[1].get();
			if (internalRT == null) {
				internalRT = Image.createRenderTarget(iron.App.w(), iron.App.h(), kha.graphics4.TextureFormat.RGBA32, NoDepthAndStencil);
			}
			sourceImg = internalRT;
			prepareInternalRender();
		}

		if (sourceImg == null || x < 0 || y < 0 || x >= sourceImg.width || y >= sourceImg.height) return null;

		var pixels = sourceImg.getPixels();
		var index: Int;

		//#if kha_html5
		index = (sourceImg.height - 1 - y) * sourceImg.width + x;
		//#else
		index = y * sourceImg.width + x;
		//#end

		var r = pixels.get(index * 4 + 0) / 255;
		var g = pixels.get(index * 4 + 1) / 255;
		var b = pixels.get(index * 4 + 2) / 255;
		var a = pixels.get(index * 4 + 3) / 255;

		return new Vec4(r, g, b, a);
	}

	function prepareInternalRender() {
		internalRT.g2.begin(true, Color.Transparent);
		if (property0 == 'Render' || property0 == 'Render&Render2D') {
			if (armory.renderpath.RenderPathCreator.finalTarget != null) {
				var img: Image = iron.RenderPath.active.renderTargets.get("buf").image;
				internalRT.g2.drawScaledImage(img, 0, 0, internalRT.width, internalRT.height);
			}
		}
		if (property0.indexOf('2D') >= 0) {
			for (f in @:privateAccess iron.App.traitRenders2D) f(internalRT.g2);
		}
		internalRT.g2.end();
	}
}