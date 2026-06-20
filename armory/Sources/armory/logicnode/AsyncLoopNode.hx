package armory.logicnode;

class AsyncLoopNode extends LogicNode {

	var from:Int;
	var to:Int;
	var index:Int;
	var running:Bool = false;
	var itemsPerFrame:Int = 1;

	public function new(tree:LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		this.from = inputs[1].get();
		this.to = inputs[2].get();
		this.itemsPerFrame = inputs[3].get();
		index = this.from;

		if (this.from >= this.to) {
			runOutput(2);
			return;
		}

		running = true;
		tree.notifyOnUpdate(update);
	}

	function update() {
		if (!running) return;

		var processed = 0;
		while (processed < itemsPerFrame && index < to) {
			runOutput(0);
			index++;
			processed++;

			if (tree.loopBreak) {
				tree.loopBreak = false;
				running = false;
				tree.removeUpdate(update);
				runOutput(2);
				return;
			}

			if (tree.loopContinue) {
				tree.loopContinue = false;
				continue;
			}
		}

		if (index >= to) {
			running = false;
			tree.removeUpdate(update);
			runOutput(2);
		}
	}

	override function get(from: Int): Dynamic {
		return index - 1;
	}
}