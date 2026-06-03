package armory.renderpath;

import iron.RenderPath;
import iron.Scene;

class DynamicResolutionScale {

	public static var dynamicScale = 1.0;
	static var lastTime = -1.0;
	static var totalTime = 0.0;
	static var frames = 0;
	static var frameTimeAvg = 0.0;
	static var stabilityCounter = 0;
	static var lastFrame = -1;

	public static function run(path: RenderPath) {
		if (path.frame == lastFrame) {
			return;
		}
		lastFrame = path.frame;

		var currentTime = kha.Scheduler.realTime();
		if (lastTime < 0) {
			lastTime = currentTime;
			return;
		}

		var delta = currentTime - lastTime;
		lastTime = currentTime;

		totalTime += delta;
		frames++;

		if (totalTime >= 1.0) {
			frameTimeAvg = (totalTime / frames) * 1000.0;
			totalTime = 0.0;
			frames = 0;

			if (frameTimeAvg > 33.3) {
				stabilityCounter++;
				if (stabilityCounter > 2 && dynamicScale > 0.5) {
					dynamicScale -= 0.15;
					applyScale(path, dynamicScale);
					stabilityCounter = 0;
				}
			}
			else if (frameTimeAvg < 28.0) {
				stabilityCounter--;
				if (stabilityCounter < -2 && dynamicScale < 1.0) {
					dynamicScale += 0.15;
					applyScale(path, dynamicScale);
					stabilityCounter = 0;
				}
			}
			else {
				stabilityCounter = 0;
			}
		}
	}

	static function applyScale(path: RenderPath, scale: Float) {
		var changed = false;
		for (rt in path.renderTargets) {
			if (rt.raw.scale != null) {
				rt.raw.scale = scale;
				changed = true;
			}
		}
		if (changed) {
			path.resize();
			updateCameraDimensions();
		}
	}

	static function updateCameraDimensions() {
		var camera = Scene.active.camera;
		if (camera != null) {
			camera.buildMatrix();
		}
	}
}