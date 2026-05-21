package armory.logicnode;

class GetWorldDataNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {

		var world = iron.Scene.active.world.raw;

		return switch (from) {
			case 0:
				world.name;
			case 1:
				world.turbidity != null ? world.probe.strength * 10 : world.probe.strength;
			case 2:
				intToColor(world.background_color);
			default: 
				null;
		}
		return null;

	}

	function intToColor(val: Int): Array<Float> {
	    var a: Float = ((val >>> 24) & 0xff) / 255.0;
	    var r: Float = ((val >> 16) & 0xff) / 255.0;
	    var g: Float = ((val >> 8) & 0xff) / 255.0;
	    var b: Float = (val & 0xff) / 255.0;
	    return [r, g, b, a];
	}
}
