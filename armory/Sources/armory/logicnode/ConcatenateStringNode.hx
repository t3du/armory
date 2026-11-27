package armory.logicnode;

class ConcatenateStringNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var value: String = "";
		for (inp in inputs) value += inp.get();
		return value;
	}
}
