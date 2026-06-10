package armory.logicnode;

import iron.system.Input;
import iron.system.Time;

class GetKeyboardNode extends LogicNode {

	public var property0: String;
	var activeKey: String = "";
	var lastTime: Float = -1.0;

	public function new(tree: LogicTree) {
		super(tree);
		tree.notifyOnUpdate(update);
	}

	function update() {
		var keyboard = Input.getKeyboard();
		var found = false;

		for (k in iron.system.Keyboard.keys) {
			var b = false;
			switch (property0) {
				case "started":
					b = keyboard.started(k);
				case "down":
					b = keyboard.down(k);
				case "released":
					b = keyboard.released(k);
			}

			if (b) {
				if (property0 == "started" || property0 == "released") {
					var currentTime = Time.time();
					if (currentTime == lastTime) continue;
					lastTime = currentTime;
				}
				activeKey = k;
				found = true;
				break;
			}
		}

		if (found) {
			runOutput(0);
		}
	}

	override function get(from: Int): Dynamic {
		return activeKey;
	}
}