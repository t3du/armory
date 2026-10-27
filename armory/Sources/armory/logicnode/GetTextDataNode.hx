package armory.logicnode;

import iron.object.TextObject;
import iron.math.Vec4;

class GetTextDataNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var textObject: TextObject = inputs[0].get();
		if (textObject == null) return null;

		return switch (from) {
			case 0: textObject.fontFile;
			case 1: textObject.text;
			case 2: textObject.worldScale;
			case 3: textObject.extrusionDepth;
			case 4: textObject.curveSteps;
			case 5: textObject.materials != null && textObject.materials.length > 0 ? textObject.materials[0] : null;
			case 6: textObject.materials != null && textObject.materials.length > 1 ? textObject.materials[1] : (textObject.extrusionDepth != 0 && textObject.materials != null && textObject.materials.length > 0 ? textObject.materials[0] : null);
			case 7: new Vec4(textObject.outlineColor.R, textObject.outlineColor.G, textObject.outlineColor.B, textObject.outlineColor.A);
			case 8: textObject.outlineStrength;
			case 9: textObject.textMesh;
			case 10: textObject.fill;
			default: null;
		};
	}

}
