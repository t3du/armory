package armory.logicnode;

import kha.Font;
import kha.Color;
import armory.renderpath.RenderToTexture;
import kha.graphics2.VerTextAlignment;
import kha.graphics2.HorTextAlignment;

#if arm_ui
import armory.ui.Canvas;

using zui.GraphicsExtension;
#end

class DrawStringNode extends LogicNode {
	var font: Font;
	var lastFontName = "";
	var string:String;

	public var property1: String;
	public var property2: String;

	public function new(tree: LogicTree) {
		super(tree);
	}

	#if arm_ui
	override function run(from: Int) {
		RenderToTexture.ensure2DContext("DrawStringNode");

		var horA = TextLeft;
		var verA = TextTop;

		string = Std.string(inputs[1].get());
		var angle: Float = inputs[7].get();

		var fontName = inputs[2].get();
		if (fontName == "") {
			#if arm_ui
			fontName = Canvas.defaultFontName;
			#else
			return; // No default font is exported, there is nothing we can do here
			#end
		}

		if (fontName != lastFontName) {
			// Load new font
			lastFontName = fontName;
			iron.data.Data.getFont(fontName, (f: Font) -> {
				font = f;
			});
		}

		if (font == null) {
			runOutput(0);
			return;
		}

		switch(property1){
			case 'TextLeft': horA = TextLeft;
			case 'TextCenter': horA = TextCenter;
			case 'TextRight': horA = TextRight;
		}

		switch(property2){
			case 'TextTop': verA = TextTop;
			case 'TextMiddle': verA = TextMiddle;
			case 'TextBottom': verA = TextBottom;
		}

		var posX: Float = inputs[5].get();
		var posY: Float = inputs[6].get();

		RenderToTexture.g.rotate(angle, posX, posY);

		RenderToTexture.g.fontSize = inputs[3].get();
		RenderToTexture.g.font = font;

		var borderSize: Float = inputs[9].get();

		if (borderSize > 0) {
			final bcv = inputs[8].get();
			RenderToTexture.g.color = Color.fromFloats(bcv.x, bcv.y, bcv.z, bcv.w);

			while (borderSize > 0) {
				var ringSteps = Std.int(Math.max(8, Math.ceil(borderSize * 4)));
				if (ringSteps > 24) ringSteps = 24;
				var ringAngle = (2 * Math.PI) / ringSteps;
				for (i in 0...ringSteps) {
					var ox = Math.cos(i * ringAngle) * borderSize;
					var oy = Math.sin(i * ringAngle) * borderSize;
					RenderToTexture.g.drawAlignedString(string, posX + ox, posY + oy, horA, verA);
				}
				borderSize -= 1.5;
			}
		}

		final colorVec = inputs[4].get();
		RenderToTexture.g.color = Color.fromFloats(colorVec.x, colorVec.y, colorVec.z, colorVec.w);

		RenderToTexture.g.drawAlignedString(string, posX, posY, horA, verA);

		RenderToTexture.g.rotate(-angle, posX, posY);

		runOutput(0);
	}

	override function get(from: Int): Dynamic {

		return from == 1 ? RenderToTexture.g.font.width(RenderToTexture.g.fontSize, string) : RenderToTexture.g.font.height(RenderToTexture.g.fontSize);
	
	}
	#end
}
