package armory.logicnode;

import iron.object.TextObject;
import iron.data.MaterialData;
import iron.math.Vec4;
import kha.Color;
import haxe.ds.Vector;

class SetTextDataNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var textObject: TextObject = inputs[1].get();
		if (textObject == null) {
			runOutput(0);
			return;
		}

		textObject.fontFile = inputs[2].get();
		textObject.text = inputs[3].get();
		textObject.worldScale = inputs[4].get();
		textObject.extrusionDepth = inputs[5].get();
		textObject.curveSteps = inputs[6].get();
		var fillMaterial: MaterialData = inputs[7].get();
		var sideMaterial: MaterialData = inputs[8].get();
		var materials = new Vector<MaterialData>(sideMaterial != null ? 2 : 1);
		materials[0] = fillMaterial;
		if (sideMaterial != null) materials[1] = sideMaterial;
		textObject.materials = materials;

		var color: Vec4 = inputs[9].get();
		if (color != null) textObject.outlineColor = Color.fromFloats(color.x, color.y, color.z, color.w);
		textObject.outlineStrength = inputs[10].get();
		textObject.fill = inputs[11].get();
		textObject.generate();
		runOutput(0);
	}

	override function get(from: Int): Dynamic {
		var textObject: TextObject = inputs[1].get();
		return textObject != null ? textObject.textMesh : null;
	}
}
