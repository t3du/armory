package armory.logicnode;

import iron.math.Vec4;

class RandomColorNode extends LogicNode {

	public var property0: Bool;
	public var property1: Bool;
	public var property2: Bool;
	public var property3: Bool;

	public var property4: Float;
	public var property5: Float;
	public var property6: Float;
	public var property7: Float;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {

		var r = property0 ? Math.random() : property4;
		var g = property1 ? Math.random() : property5;
		var b = property2 ? Math.random() : property6;
		var a = property3 ? Math.random() : property7;

		return new Vec4(r, g, b, a);
	}
}