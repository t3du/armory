package armory.logicnode;

import iron.App;

class ReorderRender2DNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {		
		App.moveRender2D(inputs[1].get(), inputs[2].get());
		runOutput(0);
	}

	override function get(from: Int): Dynamic { 
		return @:privateAccess App.traitRenders2D.indexOf(inputs[1].get()); 
	}

}