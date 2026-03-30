package armory.logicnode;

import iron.object.Object;
import iron.math.Vec4;
import armory.trait.physics.bullet.SoftBody;

class GetSoftBodyDataNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var obj: Object = inputs[0].get();
		if (obj == null) return null;

		var sb = obj.getTrait(SoftBody);
		if (sb == null) return null;

		return switch (from) {
			case 0: true; // Has SB
			case 1: @:privateAccess sb.mass;
			case 2: @:privateAccess sb.bend;
			case 3: @:privateAccess sb.shape;
			case 4: @:privateAccess sb.margin;
			case 5: new Vec4(sb.vertOffsetX, sb.vertOffsetY, sb.vertOffsetZ);
			default: null;
		}
	}
}