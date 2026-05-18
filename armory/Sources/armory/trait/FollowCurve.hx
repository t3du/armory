
import iron.object.CurveObject;
import iron.Scene;

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
	var advanced: Bool = false;

	@prop
	var speed: Float = 0.1;

	@prop
	var equidistantSamples: Int = 0;

	@prop
	var forward: Bool = true;

	@prop
	var cyclic: Bool = true;

	public function new() {
		super();

		notifyOnInit(function() {
			var obj = iron.Scene.active.getChild(curveName);
			if (obj != null && Std.isOfType(obj, CurveObject)) {
				curve = cast obj;
				curve.equidistantSamples = equidistantSamples;
			}
		});

		notifyOnUpdate(function() {
			if (curve == null) return;

			progress += (speed * iron.system.Time.delta * (forward ? 1.0 : -1.0));

			if (cyclic){
				if (progress > 1.0) progress -= 1.0;
				else if (progress < 0.0) progress += 1.0;
			}

			curve.follow(object, progress, splineIndex, forwardAxis, advanced);
		});
	}
}