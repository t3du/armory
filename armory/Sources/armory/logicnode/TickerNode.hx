package armory.logicnode;

class TickerNode extends LogicNode {

	var timer: haxe.Timer;
	var startTime: Float = 0;
	var elapsedTime: Float = 0;
	var count: Int = 0;

	public function new(tree: LogicTree) {
		super(tree);
		tree.notifyOnRemove(onRemove);
	}

	override function run(from: Int) {
		if (timer != null) timer.stop();
		timer = null;

		if (from == 0) {
			startTime = haxe.Timer.stamp();
			count = 0;

			timer = new haxe.Timer(Std.int(inputs[2].get() * 1000));
			timer.run = function() {
				count++;
				runOutput(0);
			};
		}
	}

	override function get(from: Int): Dynamic {
		if (from == 1) {
			if (timer != null) elapsedTime = haxe.Timer.stamp() - startTime;
			return elapsedTime;
		}
		else 
			return count;
	}

	function onRemove():Void {
		if (timer != null) {
			timer.stop();
			timer = null;
		}
	}
}