package armory.logicnode;

import iron.Scene;

class GroupNode extends LogicNode {

	public var property0: String;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		return from == 0 ? Scene.active.getGroup(property0) : Scene.active.getGroup(property0).length;
	}
}
