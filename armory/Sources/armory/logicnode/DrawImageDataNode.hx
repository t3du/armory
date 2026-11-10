package armory.logicnode;

import iron.math.Vec4;
import kha.Image;
import kha.Color;
import kha.graphics4.PipelineState;
import kha.graphics4.BlendingFactor;
import kha.graphics4.TextureFormat;
import kha.graphics4.DepthStencilFormat;
import kha.graphics4.Graphics2 as G4G2;
import armory.renderpath.RenderToTexture;
import haxe.io.Bytes;

#if arm_ui
using zui.GraphicsExtension;
#end

class DrawImageDataNode extends LogicNode {
	var img: Image = null;
	var maskedImg: Null<Image> = null;
	var lastData: Dynamic = null;
	var loadId: Int = 0;
	var isDecoding: Bool = false;
	var lastShape: Int = -1;
	var lastRadius: Float = -1;
	var lastWidth: Int = -1;
	var lastHeight: Int = -1;
	static var maskPipeline: Null<PipelineState> = null;

	public function new(tree: LogicTree) {
		super(tree);
		tree.notifyOnRemove(() -> {
			if (maskedImg != null) maskedImg.unload();
			if (img != null) img.unload();
			maskedImg = null;
			img = null;
		});
	}

	static function getMaskPipeline(): PipelineState {
		if (maskPipeline == null) {
			var structure = G4G2.createImageVertexStructure();
			maskPipeline = G4G2.createImagePipeline(structure);
			maskPipeline.blendSource = DestinationAlpha;
			maskPipeline.blendDestination = BlendZero;
			maskPipeline.alphaBlendSource = DestinationAlpha;
			maskPipeline.alphaBlendDestination = BlendZero;
			maskPipeline.compile();
		}
		return maskPipeline;
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

	function createMask(width: Int, height: Int, shape: Int, radius: Float) {
		if (maskedImg == null || maskedImg.width != width || maskedImg.height != height) {
			if (maskedImg != null) maskedImg.unload();
			maskedImg = Image.createRenderTarget(width, height, TextureFormat.RGBA32, DepthStencilFormat.NoDepthAndStencil);
		}

		var g = RenderToTexture.g;
		g.end();

		var draw = maskedImg.g2;
		draw.begin(true, Color.fromBytes(0, 0, 0, 0));
		draw.color = Color.White;

		var r = Math.max(0, Math.min(radius, Math.min(width, height) * 0.5));

		if (shape == 2) {
			draw.fillCircle(width * 0.5, height * 0.5, Math.min(width, height) * 0.5, 0);
		}
		else if (shape == 1) {
			if (r <= 0) {
				draw.fillRect(0, 0, width, height);
			}
			else {
				draw.fillRect(r, 0, width - 2 * r, height);
				draw.fillRect(0, r, width, height - 2 * r);

				draw.fillCircle(r, r, r, 0);
				draw.fillCircle(width - r, r, r, 0);
				draw.fillCircle(width - r, height - r, r, 0);
				draw.fillCircle(r, height - r, r, 0);
			}
		}
		else {
			draw.fillRect(0, 0, width, height);
		}

		draw.end();
		draw.begin(false);
		draw.pipeline = getMaskPipeline();
		draw.color = Color.White;
		draw.drawScaledImage(img, 0, 0, width, height);
		draw.pipeline = null;
		draw.end();

		g.begin(false);
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
		final shape: Int = inputs[10].get();
		final radius: Float = inputs[11].get();

		final drawx = x - 0.5 * width * anchorH;
		final drawy = y - 0.5 * height * anchorV;

		if (data != null && data != lastData && !isDecoding) {
			lastData = data;
			final currentLoad = ++loadId;
			if (img != null) img.unload();
			if (maskedImg != null) maskedImg.unload();
			img = null;
			maskedImg = null;
			isDecoding = true;

			Image.fromEncodedBytes(getBytes(data), "jpg", (loadedImage: Image) -> {
				#if kha_krom
				var uploadImage = Image.fromBytes(loadedImage.getPixels(), loadedImage.width, loadedImage.height, TextureFormat.RGBA32);
				loadedImage.unload();
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
				lastShape = -1;
			}, (err: String) -> {
				trace("DrawImageDataNode ERROR: " + err);
				isDecoding = false;
			}, true);
		}

		if (img != null) {
			if (shape != 0 && (shape != lastShape || radius != lastRadius || img.width != lastWidth || img.height != lastHeight || maskedImg == null)) {
				createMask(img.width, img.height, shape, radius);
				lastShape = shape;
				lastRadius = radius;
				lastWidth = img.width;
				lastHeight = img.height;
			}

			RenderToTexture.g.rotate(angle, x, y);
			RenderToTexture.g.color = Color.fromFloats(colorVec.x, colorVec.y, colorVec.z, colorVec.w);
			RenderToTexture.g.drawScaledImage(shape == 0 ? img : maskedImg, drawx, drawy, width, height);
			RenderToTexture.g.rotate(-angle, x, y);
		}

		runOutput(0);
	}
}