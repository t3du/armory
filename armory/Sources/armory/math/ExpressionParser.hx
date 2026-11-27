package armory.math;

class MathExpressionParser {

	var expression: String;
	var variables: Map<String, Float>;
	var pos: Int = 0;

	public function new(expression: String, variables: Map<String, Float>) {
		this.expression = expression;
		this.variables = variables;
	}

	public static function evaluate(expression: String, variables: Map<String, Float>): Float {
		var parser = new MathExpressionParser(expression, variables);
		return parser.parseExpression();
	}

	function skipSpaces(): Void {
		while (pos < expression.length && StringTools.isSpace(expression, pos)) {
			pos++;
		}
	}

	function match(value: String): Bool {
		skipSpaces();

		if (StringTools.startsWith(expression.substr(pos), value)) {
			pos += value.length;
			return true;
		}

		return false;
	}

	function parseExpression(): Float {
		return parseComparison();
	}

	function parseComparison(): Float {
		var value = parseAddSubtract();

		while (true) {
			if (match("<=")) value = value <= parseAddSubtract() ? 1 : 0;
			else if (match(">=")) value = value >= parseAddSubtract() ? 1 : 0;
			else if (match("<")) value = value < parseAddSubtract() ? 1 : 0;
			else if (match(">")) value = value > parseAddSubtract() ? 1 : 0;
			else break;
		}

		return value;
	}

	function parseAddSubtract(): Float {
		var value = parseMultiplyDivide();

		while (true) {
			if (match("+")) value += parseMultiplyDivide();
			else if (match("-")) value -= parseMultiplyDivide();
			else break;
		}

		return value;
	}

	function parseMultiplyDivide(): Float {
		var value = parsePower();

		while (true) {
			if (match("*")) value *= parsePower();
			else if (match("/")) value /= parsePower();
			else if (match("%")) value %= parsePower();
			else break;
		}

		return value;
	}

	function parsePower(): Float {
		var value = parseUnary();

		if (match("^")) {
			value = Math.pow(value, parsePower());
		}

		return value;
	}

	function parseUnary(): Float {
		if (match("-")) return -parseUnary();
		if (match("+")) return parseUnary();

		return parsePrimary();
	}

	function parsePrimary(): Float {
		skipSpaces();

		if (match("(")) {
			var value = parseExpression();
			match(")");
			return value;
		}

		var start = pos;

		while (pos < expression.length) {
			var c = expression.charAt(pos);

			if ((c >= "0" && c <= "9") || c == ".") {
				pos++;
			}
			else break;
		}

		if (pos > start) {
			return Std.parseFloat(expression.substring(start, pos));
		}

		start = pos;

		while (pos < expression.length) {
			var c = expression.charAt(pos);

			if ((c >= "a" && c <= "z") || (c >= "A" && c <= "Z")) {
				pos++;
			}
			else break;
		}

		if (pos == start) {
			throw "Unexpected character at position " + pos;
		}

		var name = expression.substring(start, pos).toLowerCase();

		if (match("(")) {
			var args = new Array<Float>();

			if (!match(")")) {
				do {
					args.push(parseExpression());
				}
				while (match(","));

				match(")");
			}

			return callFunction(name, args);
		}

		if (variables.exists(name)) {
			return variables.get(name);
		}

		if (name == "pi") return Math.PI;
		if (name == "e") return Math.exp(1);

		throw "Unknown variable: " + name;
	}

	function callFunction(name: String, args: Array<Float>): Float {
		var a = args.length > 0 ? args[0] : 0.0;
		var b = args.length > 1 ? args[1] : 0.0;

		switch (name) {
			case "sin": return Math.sin(a);
			case "cos": return Math.cos(a);
			case "tan": return Math.tan(a);

			case "asin": return Math.asin(a);
			case "acos": return Math.acos(a);
			case "atan": return Math.atan(a);
			case "atan2": return Math.atan2(a, b);

			case "sinh": return (Math.exp(a) - Math.exp(-a)) / 2;
			case "cosh": return (Math.exp(a) + Math.exp(-a)) / 2;
			case "tanh":
				var e2 = Math.exp(2 * a);
				return (e2 - 1) / (e2 + 1);

			case "abs": return Math.abs(a);
			case "sqrt": return Math.sqrt(a);
			case "log": return Math.log(a);
			case "exp": return Math.exp(a);

			case "floor": return Math.floor(a);
			case "ceil": return Math.ceil(a);
			case "round": return Math.floor(a / b + 0.5) * b;
			case "fract": return a - Math.floor(a);

			case "min": return Math.min(a, b);
			case "max": return Math.max(a, b);
			case "pow": return Math.pow(a, b);
			case "mod": return a % b;

			case "pingpong":
				var t = a % (2 * b);
				return b - Math.abs(t - b);

			default:
				throw "Unknown function: " + name;
		}
	}
}