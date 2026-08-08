package armory.trait;

import iron.object.CurveObject;
import iron.Scene;
import iron.system.Time;

class FollowCurve extends iron.Trait {

	var curve: CurveObject = null;
	var progress: Float = 0.0;

	@prop
	var curveName: String = "";

	@prop 
	var splineIndex: Int = 0;

	@prop 
	var forwardAxis: String = 'X';

	@prop
	var speed: Float = 1;

	@prop
	var equidistantSamples: Int = 0;

	@prop
	var forward: Bool = true;

	@prop
	var cyclic: Bool = true;

	@prop
	var start: Float = 0.0;

	public function new() {
		super();

		notifyOnInit(function() {
			var obj = Scene.active.getChild(curveName);
			if (obj != null && Std.isOfType(obj, CurveObject)) {
				curve = cast obj;
				curve.equidistantSamples = equidistantSamples;
				progress = start;
				notifyOnUpdate(update);
			}
		});
	}

	function update() {
			var len = curve.getLength(splineIndex);
			var currentDist = progress * len;
			currentDist += (speed * Time.delta * (forward ? 1.0 : -1.0));

			if (cyclic){
				if (currentDist > len) currentDist -= len;
				else if (currentDist < 0) currentDist += len;
			}

			progress = (len > 0) ? currentDist / len : 0.0;

			curve.follow(object, progress, splineIndex, forwardAxis);
	};
}