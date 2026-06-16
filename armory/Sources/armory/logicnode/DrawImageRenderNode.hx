package armory.logicnode;

import iron.math.Vec4;
import iron.RenderPath;
import kha.Image;
import kha.Color;
import armory.renderpath.RenderToTexture;

class DrawImageRenderNode extends LogicNode {
	var img: Image;
	var img2D: Image;
	var initialized: Bool = false;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {

		if (from == 1){
			if (inputs[16].get()){
				if (initialized) return;
				initialized = true;
			}

			img = kha.Image.createRenderTarget(iron.App.w(), iron.App.h(),
				kha.graphics4.TextureFormat.RGBA32,
				kha.graphics4.DepthStencilFormat.NoDepthAndStencil);
			if (inputs[15].get() || kha.Image.renderTargetsInvertedY())
				img2D = kha.Image.createRenderTarget(iron.App.w(), iron.App.h(),
					kha.graphics4.TextureFormat.RGBA32,
					kha.graphics4.DepthStencilFormat.NoDepthAndStencil);
			tree.notifyOnRender(render);
		}
		else {
			RenderToTexture.ensure2DContext("DrawImageRenderNode");

			final colorVec: Vec4 = inputs[3].get();
			final anchorH: Int = inputs[4].get();
			final anchorV: Int = inputs[5].get();
			final x: Float = inputs[6].get();
			final y: Float = inputs[7].get();
			final width: Float = inputs[8].get();
			final height: Float = inputs[9].get();
			final sx: Float = inputs[10].get();
			final sy: Float = inputs[11].get();
			final swidth: Float = inputs[12].get();
			final sheight: Float = inputs[13].get();
			final angle: Float = inputs[14].get();

			final drawx = x - 0.5 * width * anchorH;
			final drawy = y - 0.5 * height * anchorV;

			RenderToTexture.g.rotate(angle, x, y);

			RenderToTexture.g.color = 0xff000000;
			RenderToTexture.g.fillRect(drawx, drawy, width, height);
			RenderToTexture.g.color = RenderToTexture.g.color = Color.fromFloats(colorVec.x, colorVec.y, colorVec.z, colorVec.w);
			
			if ((inputs[15].get() || kha.Image.renderTargetsInvertedY()) && img2D != null)
				RenderToTexture.g.drawScaledSubImage(img2D, sx, sy, swidth, sheight, drawx, drawy, width, height);
			else if(img != null)
				RenderToTexture.g.drawScaledSubImage(img, sx, sy, swidth, sheight, drawx, drawy, width, height);

			RenderToTexture.g.rotate(-angle, x, y);

			runOutput(0);
		}

	}

	function render(g: kha.graphics4.Graphics) {
		final rpPaused = RenderPath.active.paused;
		RenderPath.active.paused = false;

		var camera = inputs[2].get();

		final sceneCam = iron.Scene.active.camera;
		final oldRT = camera.renderTarget;

		iron.Scene.active.camera = camera;
		camera.renderTarget = img;

		camera.renderFrame(g);

		if (inputs[15].get() || kha.Image.renderTargetsInvertedY()) {

			img2D.g2.begin(true, Color.Transparent);
			img2D.g2.color = Color.White;

			if (kha.Image.renderTargetsInvertedY())
				img2D.g2.drawScaledImage(camera.renderTarget, 0, iron.App.h(), iron.App.w(), -iron.App.h());
			else
				img2D.g2.drawImage(camera.renderTarget, 0, 0);

			if (inputs[15].get())
				for (f in @:privateAccess iron.App.traitRenders2D)
					f(img2D.g2);

			img2D.g2.end();
		}

		camera.renderTarget = oldRT;
		iron.Scene.active.camera = sceneCam;

		RenderPath.active.paused = rpPaused;

		if (!inputs[16].get())
			tree.removeRender(render);

	}

}