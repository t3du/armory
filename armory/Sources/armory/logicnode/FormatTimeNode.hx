package armory.logicnode;

class FormatTimeNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var time: Float = inputs[0].get();
		var format: String = inputs[1].get();

		var totalSeconds = Math.floor(time);
		var milliseconds = Math.floor((time - totalSeconds) * 1000);
		var centiseconds = Math.floor(milliseconds / 10);
		
		var h = Math.floor(totalSeconds / 3600);
		var m = Math.floor((totalSeconds % 3600) / 60);
		var s = totalSeconds % 60;

		var result = format;
		result = StringTools.replace(result, "HH", (h < 10 ? "0" : "") + h);
		result = StringTools.replace(result, "MM", (m < 10 ? "0" : "") + m);
		result = StringTools.replace(result, "SS", (s < 10 ? "0" : "") + s);
		result = StringTools.replace(result, "MS", (centiseconds < 10 ? "0" : "") + centiseconds);
		result = StringTools.replace(result, "H", "" + h);
		result = StringTools.replace(result, "M", "" + m);
		result = StringTools.replace(result, "S", "" + s);

		return result;
	}
}