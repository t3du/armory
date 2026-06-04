package armory.renderpath;

import iron.RenderPath;

class DynamicResolutionScale {

	public static var enabled = true;
	public static var dynamicScale = 1.0;
	
	static inline var targetMs = 30.0;
	static inline var rangeMs = 10.0;
	static inline var minScale = 0.6;

	static var lastTime = 0.0;
	static var totalTime = 0.0;
	static var frames = 0;
	static var frameTimeAvg = 0.0;
	static var needsResize = false;

	public static function run(path: RenderPath) {
		if (!enabled) {
			if (dynamicScale != 1.0) {
				dynamicScale = 1.0;
				needsResize = true;
			}
			return;
		}

		var now = kha.Scheduler.realTime();
		totalTime += (now - lastTime);
		lastTime = now;
		frames++;

		if (totalTime >= 1.0) {
			frameTimeAvg = (totalTime / frames) * 1000.0;
			totalTime = 0.0;
			frames = 0;

			var newScale = (frameTimeAvg > targetMs) ? 
				(1.0 - (Math.min(rangeMs, frameTimeAvg - targetMs) / rangeMs) * (1.0 - minScale)) : 1.0;
			
			if (newScale != dynamicScale) {
				dynamicScale = newScale;
				needsResize = true;
			}
		}

		if (needsResize) {
			iron.App.notifyOnRender(function(g: kha.graphics4.Graphics) {
				for (rt in path.renderTargets) {
					if (rt.raw.scale != null) rt.raw.scale = dynamicScale;
				}
				path.resize();
			});
			needsResize = false;
		}
	}
}