package armory.trait.internal;

// To create a custom loading screen copy this file to blend_root/Sources/arm/LoadingScreen.hx

class LoadingScreen {

	static var font = null;
	static var randomColorR: Float = 0;
	static var randomColorG: Float = 0;
	static var randomColorB: Float = 0;
	static var isInitialized = false;

	public static function render(g: kha.graphics2.Graphics, assetsLoaded: Int, assetsTotal: Int) {
		
		if (!isInitialized) {
			randomColorR = Math.random();
			randomColorG = Math.random();
			randomColorB = Math.random();
			isInitialized = true;
		}

		var progress = assetsLoaded / assetsTotal;
		var r = progress * randomColorR;
		var gg = progress * randomColorG;
		var b = progress * randomColorB;

		g.color = kha.Color.fromFloats(r, gg, b, 1);
		g.fillRect(0, iron.App.h() - 50, iron.App.w() / assetsTotal * assetsLoaded, 50);

		if (font == null)
			iron.data.Data.getFont('font_default.ttf', (f: kha.Font) -> {
				font = f;
				});
		else {
			g.font = font;
			g.fontSize = 50;
			g.color = 0xffffffff;
			g.drawString(Math.floor(progress*100)+'%', iron.App.w() / assetsTotal * assetsLoaded - 80, iron.App.h() - 50);
		}
		
	}
}
