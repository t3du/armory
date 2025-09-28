package armory.logicnode;

import iron.data.SceneFormat;
import iron.data.WorldData;

class SetWorldProbeNode extends LogicNode {

	var probe = null;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		if (from == 0){
			var world: String = inputs[2].get();
			iron.data.Data.getWorld(iron.Scene.active.raw.name, world, function(world: WorldData) {
				probe = iron.Scene.active.world.probe;
				iron.Scene.active.world.probe = world.probe;
			});
		}
		else
			if (probe != null)
				iron.Scene.active.world.probe = probe;

		runOutput(0);
	}
}
