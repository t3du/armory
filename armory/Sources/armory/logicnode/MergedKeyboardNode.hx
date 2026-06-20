package armory.logicnode;

import iron.system.Time;

class MergedKeyboardNode extends LogicNode {

	public var property0: String;
	public var property1: String;
	var lastTime: Float = -1.0;

	public function new(tree: LogicTree) {
		super(tree);

		tree.notifyOnUpdate(update);
	}

	function update() {
		var keyboard = iron.system.Input.getKeyboard();
		var b = false;
		switch (property0) {
		case "started":
			b = keyboard.started(property1);
		case "down":
			b = keyboard.down(property1);
		case "released":
			b = keyboard.released(property1);
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
		var keyboard = iron.system.Input.getKeyboard();
		switch (property0) {
		case "started":
			return keyboard.started(property1);
		case "down":
			return keyboard.down(property1);
		case "released":
			return keyboard.released(property1);
		}
		return false;
	}
}