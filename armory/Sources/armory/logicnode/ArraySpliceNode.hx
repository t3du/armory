package armory.logicnode;

class ArraySpliceNode extends LogicNode {

	var splice: Array<Dynamic>;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var ar: Array<Dynamic> = inputs[1].get();
		assert(Error, ar != null, 'Array should not be null');

		var i = inputs[2].get();
		var len = inputs[3].get();

		splice = ar.splice(i, len);

		runOutput(0);
	}

	override function get(from: Int): Dynamic {

		return splice;

	}
}
