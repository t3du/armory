package armory.logicnode;

class ActiveSceneObjectNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic { 
		return iron.Scene.active.root.getChild(iron.Scene.active.raw.name); 
	}
}
