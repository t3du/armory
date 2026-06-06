package armory.logicnode;

import iron.object.MeshObject;

class GetObjectShapeKeyNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		#if arm_morph_target
		var object: Dynamic = inputs[0].get();
		var shapeKey: String = inputs[1].get();

		assert(Error, object != null, "Object should not be null");
		var morph = cast(object, MeshObject).morphTarget;

		assert(Error, morph != null, "Object does not have shape keys");

		if (morph.morphMap.exists(shapeKey))
			return morph.morphWeights.get(morph.morphMap.get(shapeKey));
		#end
		return 0.0;

		runOutput(0);
	}
}
