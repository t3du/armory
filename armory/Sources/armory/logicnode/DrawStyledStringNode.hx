package armory.logicnode;

import kha.Font;
import kha.Color;
import kha.Image;
import kha.graphics4.PipelineState;
import kha.graphics4.BlendingFactor;
import kha.graphics4.TextureFormat;
import kha.graphics4.DepthStencilFormat;
import kha.graphics4.Graphics2 as G4G2;
import kha.graphics2.VerTextAlignment;
import kha.graphics2.HorTextAlignment;
import armory.renderpath.RenderToTexture;
import iron.math.Vec4;

#if arm_ui
import armory.ui.Canvas;

using zui.GraphicsExtension;
#end

class DrawStyledStringNode extends LogicNode {
	var font: Font;
	var lastFontName = "";
	var img: kha.Image;
	var lastImgName = "";
	var string: String = "";
	var rt: Null<kha.Image> = null;
	var maskTarget: Null<kha.Image> = null;
	var horizontalTarget: Null<kha.Image> = null;
	var outlineTarget: Null<kha.Image> = null;
	var outlineWidth = 0;
	var outlineHeight = 0;

	static var maskPipeline: Null<PipelineState> = null;
	static var outlineHorizontalPipeline: Null<PipelineState> = null;
	static var outlineVerticalPipeline: Null<PipelineState> = null;

	public var property1: String;
	public var property2: String;

	public function new(tree: LogicTree) {
		super(tree);
		#if arm_ui
		tree.notifyOnRemove(() -> {
			if (rt != null) {
				rt.unload();
				rt = null;
			}
			if (maskTarget != null) maskTarget.unload();
			if (horizontalTarget != null) horizontalTarget.unload();
			if (outlineTarget != null) outlineTarget.unload();
		});
		#end
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

	#if arm_ui
	override function run(from: Int) {
		RenderToTexture.ensure2DContext("DrawStyledStringNode");

		string = Std.string(inputs[1].get());
		if (string == "" || string == null) {
			runOutput(0);
			return;
		}

		var imgInput = inputs[2].get();
		if (Std.isOfType(imgInput, kha.Image)) {
			img = cast imgInput;
		} else if (Std.isOfType(imgInput, String)) {
			var imgName: String = cast imgInput;
			if (imgName == null || imgName == "") {
				img = null;
				lastImgName = "";
			} else if (imgName != lastImgName || img == null) {
				lastImgName = imgName;
				iron.data.Data.getImage(imgName, (image: kha.Image) -> {
					img = image;
				});
			}
		}

		var fontName = inputs[3].get();
		if (fontName == "" || fontName == null) {
			#if arm_ui
			fontName = Canvas.defaultFontName;
			#else
			return;
			#end
		}

		if (fontName != lastFontName) {
			lastFontName = fontName;
			iron.data.Data.getFont(fontName, (f: Font) -> {
				font = f;
			});
		}

		if (font == null) {
			runOutput(0);
			return;
		}

		var fontSize: Int = inputs[4].get();
		var colorVec: Vec4 = inputs[5].get();
		var posX: Float = inputs[6].get();
		var posY: Float = inputs[7].get();
		var angle: Float = inputs[8].get();
		var tileTexture: Bool = inputs[9].get();
		var tileScale: Float = inputs[10].get();
		var offsetX: Float = inputs[11].get();
		var offsetY: Float = inputs[12].get();
		var borderColorVec: Vec4 = inputs[13].get();
		var borderSize: Float = inputs[14].get();

		var textWidth = font.width(fontSize, string);
		var textHeight = font.height(fontSize);
		if (textWidth <= 0 || textHeight <= 0) {
			runOutput(0);
			return;
		}

		var xoffset = 0.0;
		switch (property1) {
			case 'TextCenter': xoffset = -textWidth * 0.5;
			case 'TextRight': xoffset = -textWidth;
			default: xoffset = 0.0;
		}

		var yoffset = 0.0;
		switch (property2) {
			case 'TextMiddle': yoffset = -textHeight * 0.5;
			case 'TextBottom': yoffset = -textHeight;
			default: yoffset = 0.0;
		}

		if (img == null) {
			RenderToTexture.g.rotate(angle, posX, posY);
			RenderToTexture.g.font = font;
			RenderToTexture.g.fontSize = fontSize;

			if (borderSize > 0 && borderColorVec != null) drawOutline(string, fontSize, textWidth, textHeight, posX + xoffset, posY + yoffset, borderSize, borderColorVec, angle, posX, posY);

			if (colorVec != null) {
				RenderToTexture.g.color = Color.fromFloats(colorVec.x, colorVec.y, colorVec.z, colorVec.w);
			}
			RenderToTexture.g.drawString(string, posX + xoffset, posY + yoffset);
			RenderToTexture.g.rotate(-angle, posX, posY);

			runOutput(0);
			return;
		}

		borderSize = Math.min(Math.max(borderSize, 0), 64);
		var pad = borderSize > 0 ? Std.int(Math.ceil(borderSize)) + 1 : 4;
		var w = Std.int(Math.ceil(textWidth)) + pad * 2;
		var h = Std.int(Math.ceil(textHeight)) + pad * 2;

		if (rt == null || rt.width < w || rt.height < h) {
			if (rt != null) {
				rt.unload();
			}
			var allocW = Std.int(Math.max(w, rt != null ? rt.width : 64));
			var allocH = Std.int(Math.max(h, rt != null ? rt.height : 32));
			if (allocW < w) allocW = w;
			if (allocH < h) allocH = h;
			rt = kha.Image.createRenderTarget(allocW, allocH, TextureFormat.RGBA32, DepthStencilFormat.NoDepthAndStencil);
		}

		var mainG = RenderToTexture.g;
		mainG.end();

		rt.g2.begin(true, Color.fromBytes(0, 0, 0, 0));
		rt.g2.font = font;
		rt.g2.fontSize = fontSize;
		rt.g2.color = Color.White;
		rt.g2.drawString(string, pad, pad);

		rt.g2.pipeline = getMaskPipeline();
		if (colorVec != null) {
			rt.g2.color = Color.fromFloats(colorVec.x, colorVec.y, colorVec.z, colorVec.w);
		} else {
			rt.g2.color = Color.White;
		}

		if (tileTexture) {
			var scale = (tileScale <= 0.0) ? 1.0 : tileScale;
			var tileW = img.width * scale;
			var tileH = img.height * scale;
			if (tileW <= 0) tileW = img.width;
			if (tileH <= 0) tileH = img.height;
			var curY: Float = -((offsetY % tileH + tileH) % tileH);
			while (curY < h) {
				var curX: Float = -((offsetX % tileW + tileW) % tileW);
				while (curX < w) {
					rt.g2.drawScaledImage(img, curX, curY, tileW, tileH);
					curX += tileW;
				}
				curY += tileH;
			}
		} else {
			var sx = offsetX % img.width;
			var sy = offsetY % img.height;
			var sw = Math.min(img.width - sx, img.width);
			var sh = Math.min(img.height - sy, img.height);
			rt.g2.drawScaledSubImage(img, sx, sy, sw, sh, 0, 0, w, h);
		}

		rt.g2.pipeline = null;
		rt.g2.end();

		mainG.begin(false);

		mainG.rotate(angle, posX, posY);

		if (borderSize > 0 && borderColorVec != null) drawOutline(string, fontSize, textWidth, textHeight, posX + xoffset, posY + yoffset, borderSize, borderColorVec, angle, posX, posY);

		mainG.color = Color.White;
		mainG.drawScaledSubImage(rt, 0, 0, w, h, posX + xoffset - pad, posY + yoffset - pad, w, h);

		mainG.rotate(-angle, posX, posY);

		runOutput(0);
	}

	function drawOutline(str: String, fontSize: Int, textWidth: Float, textHeight: Float, x: Float, y: Float, borderSize: Float, borderColor: Vec4, angle: Float, anchorX: Float, anchorY: Float) {
		borderSize = Math.min(Math.max(borderSize, 0), 64);
		if (borderSize <= 0) return;
		var pad = Std.int(Math.ceil(borderSize)) + 1;
		var w = Std.int(Math.ceil(textWidth)) + pad * 2;
		var h = Std.int(Math.ceil(textHeight)) + pad * 2;
		var lowW = Std.int(Math.ceil(w / 2));
		var lowH = Std.int(Math.ceil(h / 2));
		if (maskTarget == null || w != maskTarget.width || h != maskTarget.height || lowW != outlineWidth || lowH != outlineHeight) {
			if (maskTarget != null) maskTarget.unload();
			if (horizontalTarget != null) horizontalTarget.unload();
			if (outlineTarget != null) outlineTarget.unload();
			maskTarget = kha.Image.createRenderTarget(w, h, TextureFormat.RGBA32, DepthStencilFormat.NoDepthAndStencil);
			horizontalTarget = kha.Image.createRenderTarget(lowW, lowH, TextureFormat.RGBA32, DepthStencilFormat.NoDepthAndStencil);
			outlineTarget = kha.Image.createRenderTarget(lowW, lowH, TextureFormat.RGBA32, DepthStencilFormat.NoDepthAndStencil);
			outlineWidth = lowW;
			outlineHeight = lowH;
		}
		var mainG = RenderToTexture.g;
		mainG.end();
		maskTarget.g2.begin(true, Color.fromBytes(0, 0, 0, 0));
		maskTarget.g2.font = font;
		maskTarget.g2.fontSize = fontSize;
		maskTarget.g2.color = Color.White;
		maskTarget.g2.drawString(str, pad, pad);
		maskTarget.g2.end();
		horizontalTarget.g2.begin(true, Color.fromBytes(0, 0, 0, 0));
		horizontalTarget.g2.pipeline = getOutlineHorizontalPipeline();
		horizontalTarget.g2.color = Color.fromFloats(borderSize / 64, (w / lowW) / 4, (h / lowH) / 4, 1);
		horizontalTarget.g2.drawScaledImage(maskTarget, 0, 0, lowW, lowH);
		horizontalTarget.g2.pipeline = null;
		horizontalTarget.g2.end();
		outlineTarget.g2.begin(true, Color.fromBytes(0, 0, 0, 0));
		outlineTarget.g2.pipeline = getOutlineVerticalPipeline();
		outlineTarget.g2.color = Color.fromFloats(borderSize / 64, (w / lowW) / 4, (h / lowH) / 4, 1);
		outlineTarget.g2.drawScaledImage(horizontalTarget, 0, 0, lowW, lowH);
		outlineTarget.g2.pipeline = null;
		outlineTarget.g2.end();
		mainG.begin(false);
		mainG.rotate(angle, anchorX, anchorY);
		var previousImageScaleQuality = mainG.imageScaleQuality;
		mainG.imageScaleQuality = kha.graphics2.ImageScaleQuality.High;
		mainG.color = Color.fromFloats(borderColor.x, borderColor.y, borderColor.z, borderColor.w);
		mainG.drawScaledImage(outlineTarget, x - pad, y - pad, w, h);
		mainG.imageScaleQuality = previousImageScaleQuality;
		mainG.rotate(-angle, anchorX, anchorY);
	}

	static function getOutlineHorizontalPipeline(): PipelineState {
		if (outlineHorizontalPipeline == null) {
			var pipeline = new PipelineState();
			pipeline.inputLayout = [G4G2.createImageVertexStructure()];
			pipeline.vertexShader = kha.Shaders.painter_image_vert;
			pipeline.fragmentShader = kha.Shaders.draw_string_outline_h_frag;
			pipeline.blendSource = BlendOne; pipeline.blendDestination = BlendZero;
			pipeline.alphaBlendSource = BlendOne; pipeline.alphaBlendDestination = BlendZero;
			pipeline.compile(); outlineHorizontalPipeline = pipeline;
		}
		return outlineHorizontalPipeline;
	}

	static function getOutlineVerticalPipeline(): PipelineState {
		if (outlineVerticalPipeline == null) {
			var pipeline = new PipelineState();
			pipeline.inputLayout = [G4G2.createImageVertexStructure()];
			pipeline.vertexShader = kha.Shaders.painter_image_vert;
			pipeline.fragmentShader = kha.Shaders.draw_string_outline_v_frag;
			pipeline.blendSource = BlendOne; pipeline.blendDestination = BlendZero;
			pipeline.alphaBlendSource = BlendOne; pipeline.alphaBlendDestination = BlendZero;
			pipeline.compile(); outlineVerticalPipeline = pipeline;
		}
		return outlineVerticalPipeline;
	}

	override function get(from: Int): Dynamic {
		return from == 1 ? RenderToTexture.g.font.width(RenderToTexture.g.fontSize, string) : RenderToTexture.g.font.height(RenderToTexture.g.fontSize);
	}
	#end
}
