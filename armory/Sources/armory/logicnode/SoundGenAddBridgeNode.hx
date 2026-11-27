package armory.logicnode;

import armory.trait.internal.SoundGenerator;

class SoundGenAddBridgeNode extends LogicNode {

	var generator: SoundGenerator;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		generator = inputs[1].get();
		if (generator == null) { runOutput(0); return; }

		var startFreq: Float = inputs[2].get();
		var endFreq: Float = inputs[3].get();
		var duration: Float = inputs[4].get();
		generator.addBridge(startFreq, endFreq, duration);
		runOutput(0);
	}

	override function get(from: Int): Dynamic {
		return generator;
	}
}