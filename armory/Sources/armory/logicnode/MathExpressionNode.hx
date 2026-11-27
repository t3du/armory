package armory.logicnode;

import armory.math.ExpressionParser;

class MathExpressionNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var clamp: Bool = inputs[0].get();
		var expression: String = inputs[1].get();

		var variables: Map<String, Float> = new Map();

		for (i in 2...inputs.length) {
			var name = String.fromCharCode(97 + i - 2);
			variables.set(name, inputs[i].get());
		}

		var result = MathExpressionParser.evaluate(expression, variables);

		if (clamp) {
			result = Math.max(0, Math.min(1, result));
		}

		return result;
	}
}