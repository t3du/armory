package armory.logicnode;

import iron.system.Time;

class TimeNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		return switch (from) {
			case 0: Time.time();
			case 1: Time.delta;
			default: Time.realTime();
		}
	}
}