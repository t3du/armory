package armory.logicnode;

import iron.object.Object;
import iron.object.CurveObject;
import iron.system.Time;

class FollowCurveNode extends LogicNode {

	var progress: Float = -1;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var cycle: Bool = false;
		var object: Object = inputs[1].get();
		var curve: CurveObject = inputs[2].get();
		var splineIdx: Int = inputs[3].get();

		if (progress == -1) progress = inputs[8].get();

		var len = curve.getLength(splineIdx);
		var speed = inputs[5].get();

		var currentDist = progress * len;
		currentDist += (speed * Time.delta * (inputs[6].get() ? 1.0 : -1.0));

		if (inputs[7].get()){
			if (currentDist > len){ currentDist -= len; cycle = true; }
			else if (currentDist < 0){ currentDist += len; cycle = true; }
		}

		progress = (len > 0) ? currentDist / len : 0.0;

		if (cycle) 
			runOutput(1);
		else{
			curve.follow(object, progress, splineIdx, inputs[4].get());
			runOutput(0);
		}
	}

	override function get(from: Int): Dynamic {
		return progress;
	}
}
