package armory.logicnode;

import armory.object.BooleanCSGExtension;
import iron.object.Object;

class SeparateObjectNode extends LogicNode {

	var objects: Array<Object> = [];

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		objects = [];
		var source: Object = inputs[1].get();
		objects = BooleanCSGExtension.separateObject(source, inputs[2].get());
		runOutput(0);
		if (objects.length > 0){
		 	if (inputs[3].get()) source.remove();
		 	runOutput(1);
		} 
		else
			runOutput(2);

	}

	override function get(from: Int): Dynamic {
		return objects;
	}
}
