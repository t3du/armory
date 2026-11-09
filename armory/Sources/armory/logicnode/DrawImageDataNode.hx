package armory.logicnode;

import iron.math.Vec4;
import kha.Image;
import kha.Color;
import kha.Blob;
import armory.renderpath.RenderToTexture;
import haxe.io.Bytes;

class DrawImageDataNode extends LogicNode {

	var img: Image = null;
	var lastData: Dynamic = null;
	var loadId: Int = 0;
	var isDecoding: Bool = false;

	public function new(tree: LogicTree) {
		super(tree);
	}

	function getBytes(data: Dynamic): Bytes {
		#if kha_html5
		var uint8 = new js.lib.Uint8Array(cast data);
		var buffer = new js.lib.ArrayBuffer(uint8.length);
		var copy = new js.lib.Uint8Array(buffer);
		copy.set(uint8);
		return Bytes.ofData(buffer);
		#else
		return cast data;
		#end
	}

	override function run(from: Int) {

		RenderToTexture.ensure2DContext("DrawImageDataNode");

		final data: Dynamic = inputs[1].get();
		final colorVec: Vec4 = inputs[2].get();
		final anchorH: Int = inputs[3].get();
		final anchorV: Int = inputs[4].get();

		final x: Float = inputs[5].get();
		final y: Float = inputs[6].get();
		final width: Float = inputs[7].get();
		final height: Float = inputs[8].get();
		final angle: Float = inputs[9].get();

		final drawx = x - 0.5 * width * anchorH;
		final drawy = y - 0.5 * height * anchorV;

		if (data != null && data != lastData && !isDecoding) {

			lastData = data;
			final currentLoad = ++loadId;

			if (img != null) {
				img.unload();
				img = null;
			}

			isDecoding = true;

			var bytes = getBytes(data);

			Image.fromEncodedBytes(bytes, "jpg", (loadedImage: Image) -> {

				#if kha_krom
				var pixels = loadedImage.getPixels();
				var uploadImage = Image.fromBytes(
					pixels,
					loadedImage.width,
					loadedImage.height,
					kha.graphics4.TextureFormat.RGBA32
				);
				loadedImage.unload();
				loadedImage = null;
				#else
				var uploadImage = loadedImage;
				#end

				if (currentLoad != loadId) {
					uploadImage.unload();
					isDecoding = false;
					return;
				}

				img = uploadImage;
				isDecoding = false;

			}, (err: String) -> {
				trace("DrawImageDataNode ERROR: " + err);
				isDecoding = false;
			}, true);
		}

		if (img != null) {

			RenderToTexture.g.rotate(angle, x, y);

			RenderToTexture.g.color = Color.fromFloats(
				colorVec.x,
				colorVec.y,
				colorVec.z,
				colorVec.w
			);

			RenderToTexture.g.drawScaledImage(
				img,
				drawx,
				drawy,
				width,
				height
			);

			RenderToTexture.g.rotate(-angle, x, y);
		}

		runOutput(0);
	}
}