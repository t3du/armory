package armory.logicnode;

class FormatNumberNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var number: Float = inputs[0].get();
		var thousandsSeparator: String = inputs[1].get();
		var decimalSeparator: String = inputs[2].get();
		var includeSymbol: Bool = inputs[3].get();

		var s = Std.string(number);
		var isNegative = s.charAt(0) == "-";
		if (isNegative) s = s.substring(1);

		var parts = s.split(".");
		var integerPart = parts[0];
		var decimalPart = (parts.length > 1) ? parts[1] : "";
		
		var len = integerPart.length;
		var formattedInteger = "";
		
		if (len <= 3) {
			formattedInteger = integerPart;
		} else {
			var firstGroupLen = len % 3;
			if (firstGroupLen == 0) firstGroupLen = 3;

			formattedInteger += integerPart.substring(0, firstGroupLen);
			
			var i = firstGroupLen;
			while (i < len) {
				formattedInteger += thousandsSeparator + integerPart.substring(i, i + 3);
				i += 3;
			}
		}
		
		var finalNumber = formattedInteger;
		if (decimalPart != "") {
			finalNumber += decimalSeparator + decimalPart;
		}
		
		var result = "";
		var sign = isNegative ? "-" : "";
		
		if (includeSymbol) {
			result = sign + "$" + finalNumber;
		} else {
			result = sign + finalNumber;
		}
		
		return result;
	}
}