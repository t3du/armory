package armory.logicnode;

class ArraySetNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var ar: Array<Dynamic> = inputs[1].get();
		assert(Error, ar != null, 'Array should not be null');

		var i: Int = inputs[2].get();
		var value: Dynamic = inputs[3].get();

		if (i < 0) ar[ar.length + i] = value;
		else ar[i] = value;

		runOutput(0);
	}
}
