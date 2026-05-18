package armory.logicnode;

import iron.data.SceneFormat;
import iron.data.WorldData;
import armory.renderpath.RenderPathCreator;

class SetWorldNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var world: String = inputs[1].get();

		if (world != null){
			iron.data.Data.getWorld(iron.Scene.active.raw.name, world, function(world: WorldData) {
				iron.Scene.active.world = world;
			});

			iron.Scene.active.raw.world_ref = world;
			RenderPathCreator.path.loadShader("shader_datas/World_" + world + "/World_" + world);
		}

		runOutput(0);
	}
}
