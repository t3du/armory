package armory.logicnode;

import iron.RenderPath;
import iron.Scene;
import iron.math.Vec2;
import iron.object.CameraObject;

import armory.renderpath.RenderPathCreator;

class DrawCameraNode extends LogicNode {
	var camera: CameraObject;
	var renderTarget: kha.Image;
	var position: Vec2 = new Vec2();

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		switch (from) {
			case 0: // Start
				camera = inputs[2].get();
				position.set(
					inputs[3].get(),
					inputs[4].get()
				);

				renderTarget = kha.Image.createRenderTarget(
					inputs[5].get(), // w
					inputs[6].get(), // h
					kha.graphics4.TextureFormat.RGBA32,
					kha.graphics4.DepthStencilFormat.NoDepthAndStencil
				);

				tree.notifyOnRender(render);
				tree.notifyOnRender2D(render2D);
				runOutput(0);

			case 1: // Stop
				tree.removeRender(render);
				tree.removeRender2D(render2D);
				runOutput(1);
		}
	}

	function render(g:kha.graphics4.Graphics) {
		if (inputs[7].get()) return;
		final rpPaused = RenderPath.active.paused;
		RenderPath.active.paused = false;

		final sceneCam = iron.Scene.active.camera;

		final cam = camera;

		final oldRT = cam.renderTarget;
		cam.renderTarget = renderTarget;

		iron.Scene.active.camera = cam;
		cam.renderFrame(g);

		cam.renderTarget = oldRT;

		iron.Scene.active.camera = sceneCam;
		RenderPath.active.paused = rpPaused;
	}

	function render2D(g: kha.graphics2.Graphics) {
		if (inputs[7].get()) return;
		final rt = renderTarget;

		position.set(
					inputs[3].get(),
					inputs[4].get()
				);

		final posX = position.x;
		final posY = position.y;

		g.color = 0xff000000;
		g.fillRect(posX, posY, rt.width, rt.height);
		g.color = 0xffffffff;
		
		if (kha.Image.renderTargetsInvertedY())
			g.drawScaledImage(rt, posX, posY+rt.height, rt.width, -rt.height);
		else
			g.drawScaledImage(rt, posX, posY, rt.width, rt.height);
	}
}
