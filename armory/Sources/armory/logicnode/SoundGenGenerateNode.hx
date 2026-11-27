package armory.logicnode;

import armory.trait.internal.SoundGenerator;

class SoundGenGenerateNode extends LogicNode {

	var generator: SoundGenerator;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		generator = inputs[1].get();
		if (generator == null) { runOutput(0); return; }

		generator.generate();
		runOutput(0);
	}

	override function get(from: Int): Dynamic {
		return generator;
	}
}
