package armory.logicnode;

class AsyncArrayLoopNode extends LogicNode {

	var array:Array<Dynamic>;
	var index:Int = 0;
	var running:Bool = false;
	var itemsPerFrame:Int = 1;

	public function new(tree:LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		array = inputs[1].get();
		itemsPerFrame = inputs[2].get();
		index = 0;
		if (array == null || array.length == 0) {
			runOutput(3);
			return;
		}
		running = true;
		tree.notifyOnUpdate(update);
	}

	function update() {
		if (!running) return;

		var processed = 0;
		while (processed < itemsPerFrame && index < array.length) {
			runOutput(0);
			index++;
			processed++;
		}

		if (index >= array.length) {
			running = false;
			tree.removeUpdate(update);
			runOutput(3);
		}
	}

	override function get(from: Int): Dynamic {
		if (from == 0) return index - 1;
		else return (index > 0 && index <= array.length) ? array[index - 1] : null;
	}
}