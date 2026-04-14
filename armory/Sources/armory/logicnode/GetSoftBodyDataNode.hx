package armory.logicnode;

import iron.object.Object;
import iron.math.Vec4;
import armory.trait.physics.bullet.SoftBody;

class GetSoftBodyDataNode extends LogicNode {

	var friction: Float;
	var damping: Float;
	var pressure: Float;
	var linearStiffness: Float;
	var angularStiffness: Float;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var obj: Object = inputs[0].get();
		if (obj == null) return null;

		#if arm_physics_soft
		var sb = obj.getTrait(SoftBody);
		if (sb == null) return null;

		return switch (from) {
			case 0: true; // Has SB
			case 1: @:privateAccess sb.mass;
			case 2: @:privateAccess sb.bend;
			case 3: @:privateAccess sb.shape;
			case 4: @:privateAccess sb.margin;
			case 5: new Vec4(sb.vertOffsetX, sb.vertOffsetY, sb.vertOffsetZ);
			case 6: @:privateAccess sb.friction;
			case 7: @:privateAccess sb.damping;
			case 8: @:privateAccess sb.pressure;
			case 9: @:privateAccess sb.linearStiffness;
			case 10: @:privateAccess sb.angularStiffness;
			default: null;
		}
		#end

		return null;
	}
}