package armory.logicnode;

class GetAssetsNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		return armory.system.Starter.assets;
	}
}
