package armory.logicnode;

import iron.system.Time;

class MergedVirtualButtonNode extends LogicNode {

	public var property0: String;
	public var property1: String;
	var lastTime: Float = -1.0;

	public function new(tree: LogicTree) {
		super(tree);

		tree.notifyOnUpdate(update);
	}

	function update() {
		var vb = iron.system.Input.getVirtualButton(property1);
		if (vb == null) return;
		var b = false;
		switch (property0) {
		case "started":
			b = vb.started;
		case "down":
			b = vb.down;
		case "released":
			b = vb.released;
		}
		if (b) {
			if (property0 == "started" || property0 == "released") {
				var currentTime = Time.time();
				if (currentTime == lastTime && Time.delta != 0) return;
				lastTime = currentTime;
			}
			runOutput(0);
		}
	}

	override function get(from: Int): Dynamic {
		var vb = iron.system.Input.getVirtualButton(property1);
		if (vb == null) return false;
		switch (property0) {
		case "started":
			return vb.started;
		case "down":
			return vb.down;
		case "released":
			return vb.released;
		}
		return false;
	}
}