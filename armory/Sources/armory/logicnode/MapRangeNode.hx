package armory.logicnode;

class MapRangeNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var value: Float = inputs[0].get();
		var fromMin: Float = inputs[1].get();
		var fromMax: Float = inputs[2].get();
		var toMin: Float = inputs[3].get();
		var toMax: Float = inputs[4].get();

		var deltaFrom = fromMax - fromMin;
		if (deltaFrom == 0) return (toMin + toMax) / 2.0;

		//https://stackoverflow.com/a/5732390
		var slope = (toMax - toMin) / deltaFrom;
		return toMin + slope * (value - fromMin);
	}
}