package armory.logicnode;

class ArrayResizeNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var ar: Array<Dynamic> = inputs[1].get();
		assert(Error, ar != null, 'Array should not be null');

		var len = inputs[2].get();

		ar.resize(len);

		runOutput(0);
	}
}
