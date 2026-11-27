package armory.logicnode;

import armory.trait.internal.SoundGenerator;

class SoundGenPlayNode extends LogicNode {

	var generator: SoundGenerator;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		generator = inputs[1].get();
		if (generator == null) { runOutput(0); return; }

		if (inputs[2].get()) generator.stop();
		var loop: Bool = inputs[3].get();
		var stream: Bool = inputs[4].get();
		var volume: Float = inputs[5].get();
		generator.play(loop, stream, volume);
		if (generator.channel != null) tree.notifyOnUpdate(this.onUpdate);
		runOutput(0);
	}

	function onUpdate() {
		if (generator.channel != null && generator.channel.finished){
			generator.channel = null;
			runOutput(1);
		}
	}
}
