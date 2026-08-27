package armory.logicnode;

class CallFunctionNode extends LogicNode {

	var result: Dynamic;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var trait: Dynamic = inputs[1].get();
		if (trait == null){ runOutput(0); return; }

		var funName: String = inputs[2].get();
		var args: Array<Dynamic> = [];

		for (i in 3...inputs.length) {
			args.push(inputs[i].get());
		}

		var func = Reflect.field(trait, funName);
		if (func != null) {
			result = Reflect.callMethod(trait, func, args);
		}

		runOutput(0);
	}

	override function get(from: Int): Dynamic {
		return result;
	}
}
