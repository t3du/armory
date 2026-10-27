package armory.logicnode;

import iron.object.TextObject;
import iron.object.MeshObject;

class TextSplitNode extends LogicNode {

	var textSplit: Array<MeshObject>;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var textObject: TextObject = inputs[1].get();
		if (textObject == null) {
			runOutput(0);
			textSplit = null;
			return;
		}

		textObject.textSplit(function(chars: Array<MeshObject>) {
			textSplit = chars;
			if (inputs[2].get())
				textObject.textMesh.remove();
			if (inputs[3].get())
				for (char in chars)	
					char.setParent(textObject);
			
			runOutput(0);
		});
	}

	override function get(from: Int): Dynamic {
		return textSplit;
	}
}
