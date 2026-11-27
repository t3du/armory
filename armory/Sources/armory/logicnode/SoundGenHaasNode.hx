package armory.logicnode;

import armory.trait.internal.SoundGenerator;

class SoundGenHaasNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var generator: SoundGenerator = inputs[1].get();
		if (generator == null) { runOutput(0); return; }

		var delayMs: Float = inputs[2].get();
		generator.playHaasDSP(delayMs, function() { runOutput(1); });
		runOutput(0);
	}
	
}
