package armory.logicnode;

class GetMapKeysNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var map: Map<Dynamic, Dynamic> = inputs[0].get();
		if (map == null) return from == 0 ? null : 0;

		var keys = [for (k in map.keys()) k];

		return from == 0 ? keys : keys.length;
	}
}

