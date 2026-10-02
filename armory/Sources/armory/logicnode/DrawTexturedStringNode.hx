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

class DrawTexturedStringNode extends LogicNode {
	var font: Font;
	var lastFontName = "";
	var img: kha.Image;
	var lastImgName = "";
	var string: String = "";
	var rt: Null<kha.Image> = null;

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
		RenderToTexture.ensure2DContext("DrawTexturedStringNode");

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
			if (imgName != lastImgName || img == null) {
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
		var borderColorVec: Vec4 = inputs[11].get();
		var borderSize: Float = inputs[12].get();

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

			if (borderSize > 0 && borderColorVec != null) {
				RenderToTexture.g.color = Color.fromFloats(borderColorVec.x, borderColorVec.y, borderColorVec.z, borderColorVec.w);
				drawBorder(string, posX + xoffset, posY + yoffset, borderSize);
			}

			if (colorVec != null) {
				RenderToTexture.g.color = Color.fromFloats(colorVec.x, colorVec.y, colorVec.z, colorVec.w);
			}
			RenderToTexture.g.drawString(string, posX + xoffset, posY + yoffset);
			RenderToTexture.g.rotate(-angle, posX, posY);

			runOutput(0);
			return;
		}

		var pad = 4;
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
			var curY: Float = 0;
			while (curY < h) {
				var curX: Float = 0;
				while (curX < w) {
					rt.g2.drawScaledImage(img, curX, curY, tileW, tileH);
					curX += tileW;
				}
				curY += tileH;
			}
		} else {
			rt.g2.drawScaledImage(img, 0, 0, w, h);
		}

		rt.g2.pipeline = null;
		rt.g2.end();

		mainG.begin(false);

		mainG.rotate(angle, posX, posY);

		if (borderSize > 0 && borderColorVec != null) {
			mainG.color = Color.fromFloats(borderColorVec.x, borderColorVec.y, borderColorVec.z, borderColorVec.w);
			mainG.font = font;
			mainG.fontSize = fontSize;
			drawBorder(string, posX + xoffset, posY + yoffset, borderSize);
		}

		mainG.color = Color.White;
		mainG.drawScaledSubImage(rt, 0, 0, w, h, posX + xoffset - pad, posY + yoffset - pad, w, h);

		mainG.rotate(-angle, posX, posY);

		runOutput(0);
	}

	function drawBorder(str: String, x: Float, y: Float, borderSize: Float) {
		var r = borderSize;
		while (r > 0) {
			var ringSteps = Std.int(Math.max(8, Math.ceil(r * 4)));
			if (ringSteps > 24) ringSteps = 24;
			var ringAngle = (2 * Math.PI) / ringSteps;
			for (i in 0...ringSteps) {
				var ox = Math.cos(i * ringAngle) * r;
				var oy = Math.sin(i * ringAngle) * r;
				RenderToTexture.g.drawString(str, x + ox, y + oy);
			}
			r -= 1.5;
		}
	}

	override function get(from: Int): Dynamic {
		if (font == null) return 0.0;
		var fontSize: Int = inputs[4].get();
		return from == 1 ? font.width(fontSize, string) : font.height(fontSize);
	}
	#end
}
