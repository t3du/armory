package armory.logicnode;

class GetWorldStrengthNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var world = iron.Scene.active.world.raw;
		return world.turbidity != null ? world.probe.strength * 10 : world.probe.strength;
	}
}