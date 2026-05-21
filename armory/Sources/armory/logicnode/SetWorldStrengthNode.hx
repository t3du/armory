package armory.logicnode;

class SetWorldStrengthNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {

		if (iron.Scene.active.world.raw.turbidity != null)
			iron.Scene.active.world.raw.probe.strength = inputs[1].get() * 0.1;
		else
			iron.Scene.active.world.raw.probe.strength = inputs[1].get();

		runOutput(0);
		
	}
}
