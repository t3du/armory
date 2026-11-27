package armory.logicnode;

import armory.trait.internal.SoundGenerator;

class SoundGenGetConstantNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		return Reflect.field(SoundGenerator, inputs[0].get());
	}
}
