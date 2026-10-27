package armory.logicnode;

import iron.Scene;
import iron.object.TextObject;
import iron.math.Mat4;
import iron.math.Vec4;
import iron.data.MaterialData;
import haxe.ds.Vector;
import kha.arrays.Float32Array;

class TextObjectNode extends LogicNode {

	var textObject: TextObject;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var name: String = inputs[1].get();
		var matrix: Mat4 = inputs[2].get();
		var fontFile: String = inputs[3].get();
		var body: String = inputs[4].get();
		var worldScale: Float = inputs[5].get();
		var extrusionDepth: Float = inputs[6].get();
		var curveSteps: Int = inputs[7].get();
		var fillMaterial: MaterialData = inputs[8].get();
		var sideMaterial: MaterialData = inputs[9].get();
		var outlineColor: Vec4 = inputs[10].get();
		var outlineStrength: Float = inputs[11].get();
		var fill: Bool = inputs[12].get();

		var color = new Float32Array(4);
		if (outlineColor != null) {
			color[0] = outlineColor.x;
			color[1] = outlineColor.y;
			color[2] = outlineColor.z;
			color[3] = outlineColor.w;
		}
		else {
			color[0] = 0;
			color[1] = 0;
			color[2] = 0;
			color[3] = 1;
		}

		var data: iron.data.SceneFormat.TTextData = {
			name: name,
			object: name,
			body: body,
			font_file: fontFile,
			resolution_u: curveSteps,
			extrude: extrusionDepth,
			size: worldScale,
			fill: fill,
			outline_strength: outlineStrength,
			outline_color: color
		};
		var materials = new Vector<MaterialData>(sideMaterial != null ? 2 : 1);
		materials[0] = fillMaterial;
		if (sideMaterial != null) materials[1] = sideMaterial;
		textObject = Scene.active.addTextObject(data, materials, Scene.active.sceneParent);
		textObject.name = name;
		if (textObject.raw != null) textObject.raw.name = name;
		if (matrix != null) textObject.transform.setMatrix(matrix);

		runOutput(0);
	}

	override function get(from: Int): Dynamic {
		if (textObject == null) return null;
		return from == 1 ? textObject : textObject.textMesh;
	}
}
