package armory.logicnode;

class DelayNode extends LogicNode {

	var timer: haxe.Timer;
	var startTime: Float = 0;
	var elapsedTime: Float = 0;

	public function new(tree: LogicTree) {
		super(tree);
		tree.notifyOnRemove(onRemove);
	}

	override function run(from: Int) {
		if (timer != null) timer.stop();

		var time: Float = inputs[1].get();
		startTime = haxe.Timer.stamp();

		timer = haxe.Timer.delay(function() {
			runOutput(0);
			timer = null;
		}, Std.int(time * 1000));
	}

	override function get(from: Int): Dynamic {
		if (timer != null) elapsedTime = haxe.Timer.stamp() - startTime;
		return elapsedTime;
	}

	function onRemove():Void {
		if (timer != null) {
			timer.stop();
			timer = null;
		}
	}
}