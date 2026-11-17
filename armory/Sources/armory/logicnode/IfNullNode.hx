package armory.logicnode;

class IfNullNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var v1: Dynamic = inputs[1].get();
		if (v1 == null) runOutput(0); else runOutput(1);
	}
}
