package armory.logicnode;

import iron.Scene;
import iron.data.MaterialData;
import iron.object.Object;
import armory.trait.internal.UniformsManager;

class GetMaterialImageParamNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var object: Object = inputs[0].get();
		var perObject: Bool = inputs[1].get();
		var mat: MaterialData = inputs[2].get();
		var link: String = inputs[3].get();

		if (mat == null || link == null) return 0.0;

		if (!perObject) {
			object = Scene.active.root;
		}

		if (object == null) return 0.0;

		var val = @:privateAccess UniformsManager.getObjectTextureLink(object, mat, link);
		return val != null ? val : 0.0;
	}
}