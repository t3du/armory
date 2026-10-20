package armory.logicnode;

import kha.Font;
import kha.Color;
import kha.Image;
import kha.graphics4.PipelineState;
import kha.graphics4.BlendingFactor;
import kha.graphics4.TextureFormat;
import kha.graphics4.DepthStencilFormat;
import kha.graphics2.truetype.StbTruetype;
import kha.graphics4.Graphics2 as G4G2;
import armory.renderpath.RenderToTexture;
import armory.trait.internal.FontProcessor;
import iron.math.Vec4;

#if arm_ui
import armory.ui.Canvas;

using zui.GraphicsExtension;
#end

class DrawStyledStringNode extends LogicNode {
	var font: Font;
	var lastFontName = "";
	var outlineFont: FontProcessor;
	var lastOutlineFontName = "";
	var img: kha.Image;
	var lastImgName = "";
	var string: String = "";
	var rt: Null<kha.Image> = null;
	var measuredTextWidth: Float = 0.0;
	var measuredTextHeight: Float = 0.0;
	static var maskPipeline: Null<PipelineState> = null;

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

		var isOpenType = StringTools.endsWith(fontName.toLowerCase(), ".otf");
		if (isOpenType) {
			if (fontName != lastFontName) {
				lastFontName = fontName;
				font = null;
			}
		} else if (fontName != lastFontName) {
			lastFontName = fontName;
			font = null;
			iron.data.Data.getFont(fontName, (f: Font) -> {
				if (fontName == lastFontName) font = f;
			});
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
		if ((isOpenType || borderSize > 0) && fontName != lastOutlineFontName) {
			lastOutlineFontName = fontName;
			outlineFont = null;
			FontProcessor.load(fontName, (processor: FontProcessor) -> {
				if (fontName == lastOutlineFontName) outlineFont = processor;
			});
		}

		if (isOpenType ? outlineFont == null : font == null) {
			runOutput(0);
			return;
		}

		var fontScale = isOpenType ? StbTruetype.stbtt_ScaleForPixelHeight(outlineFont.info, fontSize) : 0.0;
		var textWidth = isOpenType ? getOutlineTextWidth(string, fontScale) : font.width(fontSize, string);
		var textHeight = isOpenType ? fontSize : font.height(fontSize);
		var baseline = isOpenType ? StbTruetype.stbtt_GetFontVMetrics(outlineFont.info).ascent * fontScale : font.baseline(fontSize);
		measuredTextWidth = textWidth;
		measuredTextHeight = textHeight;
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
			if (!isOpenType) {
				RenderToTexture.g.font = font;
				RenderToTexture.g.fontSize = fontSize;
			}
			if (borderSize > 0 && borderColorVec != null) drawOutline(string, fontSize, posX + xoffset, posY + yoffset, baseline, borderSize, borderColorVec);

			if (colorVec != null) {
				RenderToTexture.g.color = Color.fromFloats(colorVec.x, colorVec.y, colorVec.z, colorVec.w);
			}
			if (isOpenType) drawOutlineFill(RenderToTexture.g, string, fontScale, posX + xoffset, posY + yoffset + baseline);
			else RenderToTexture.g.drawString(string, posX + xoffset, posY + yoffset);
			RenderToTexture.g.rotate(-angle, posX, posY);

			runOutput(0);
			return;
		}

		borderSize = Math.max(borderSize, 0);
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
		rt.g2.color = Color.White;
		if (isOpenType) drawOutlineFill(rt.g2, string, fontScale, pad, pad + baseline);
		else {
			rt.g2.font = font;
			rt.g2.fontSize = fontSize;
			rt.g2.drawString(string, pad, pad);
		}

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

		if (borderSize > 0 && borderColorVec != null) drawOutline(string, fontSize, posX + xoffset, posY + yoffset, baseline, borderSize, borderColorVec);
		mainG.color = Color.White;
		mainG.drawScaledSubImage(rt, 0, 0, w, h, posX + xoffset - pad, posY + yoffset - pad, w, h);

		mainG.rotate(-angle, posX, posY);

		runOutput(0);
	}

	function getOutlineTextWidth(str: String, scale: Float): Float {
		var width = 0.0;
		for (i in 0...str.length) {
			var code = str.charCodeAt(i);
			if (code != 10) width += outlineFont.getAdvanceWidth(code) * scale;
		}
		return width;
	}

	function drawOutlineFill(draw: kha.graphics2.Graphics, str: String, scale: Float, x: Float, baseline: Float) {
		var cursorX = 0.0;
		for (i in 0...str.length) {
			var code = str.charCodeAt(i);
			if (code == 10) continue;
			var contours = outlineFont.getGlyphContours(code, 8);
			var triangles = outlineFont.triangulate(contours, false);
			var j = 0;
			while (j + 5 < triangles.length) {
				draw.fillTriangle(x + (cursorX + triangles[j]) * scale, baseline - triangles[j + 1] * scale,
					x + (cursorX + triangles[j + 2]) * scale, baseline - triangles[j + 3] * scale,
					x + (cursorX + triangles[j + 4]) * scale, baseline - triangles[j + 5] * scale);
				j += 6;
			}
			cursorX += outlineFont.getAdvanceWidth(code);
		}
	}

	function drawOutline(str: String, fontSize: Int, x: Float, y: Float, fontBaseline: Float, borderSize: Float, borderColor: Vec4) {
		if (outlineFont == null || borderSize <= 0) return;
		var scale = StbTruetype.stbtt_ScaleForPixelHeight(outlineFont.info, fontSize);
		var baseline = y + fontBaseline;
		var cursorX = 0.0;
		var lineWidth = borderSize * 2;
		var draw = RenderToTexture.g;
		var previousColor = draw.color;
		draw.color = Color.fromFloats(borderColor.x, borderColor.y, borderColor.z, borderColor.w);
		for (i in 0...str.length) {
			var code = str.charCodeAt(i);
			if (code == 10) continue;
			var contours = outlineFont.getGlyphContours(code, 8);
			for (contour in contours) for (j in 0...contour.length - 1) {
				var a = contour[j];
				var b = contour[j + 1];
				var ax = x + (cursorX + a.x) * scale;
				var ay = baseline - a.y * scale;
				var bx = x + (cursorX + b.x) * scale;
				var by = baseline - b.y * scale;
				draw.drawLine(ax, ay, bx, by, lineWidth);
				draw.fillCircle(ax, ay, borderSize);
			}
			cursorX += outlineFont.getAdvanceWidth(code);
		}
		draw.color = previousColor;
	}

	override function get(from: Int): Dynamic {
		return from == 1 ? measuredTextWidth : measuredTextHeight;
	}
	#end
}
