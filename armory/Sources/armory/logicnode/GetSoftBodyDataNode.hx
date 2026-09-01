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
			case 1: sb.mass;
			case 2: sb.bend;
			case 3: sb.shape;
			case 4: sb.margin;
			case 5: new Vec4(sb.vertOffsetX, sb.vertOffsetY, sb.vertOffsetZ);
			case 6: sb.friction;
			case 7: sb.damping;
			case 8: sb.pressure;
			case 9: sb.linearStiffness;
			case 10: sb.angularStiffness;
			default: null;
		}
		#end

		return null;
	}
}