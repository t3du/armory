package armory.logicnode;

import iron.object.Object;

class GetObjectTraitsNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var object: Object = inputs[0].get();
		if (object == null) return null;
		return 
		from == 0 ? object.name != null ? object.traits : inputs[0].get().root.children[0].traits :
			object.name != null ? object.traits.length : inputs[0].get().root.children[0].traits.length;
	}
}
