package armory.logicnode;

import iron.object.CurveObject;
import iron.object.MeshObject;
import iron.data.Data;
import iron.data.MaterialData;
import iron.Scene;

class SetCurveDataNode extends LogicNode {
	public var property0: String;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var curve: CurveObject = inputs[1].get();

		if (property0 == "Equidistant Samples") 
			curve.equidistantSamples = inputs[2].get();
		else if (property0 == "Strength")
			curve.data.strength = inputs[2].get();
		else if (property0 == "Color")
			curve.data.color = inputs[2].get();
		else {
			var mData = property0 == "Curve Mesh Bevel" ? 
			curve.generateBevelMesh(inputs[2].get(), inputs[3].get(), inputs[4].get(), inputs[5].get(), inputs[6].get()) : 
			curve.generateExtrudeMesh(inputs[2].get(), inputs[3].get(), inputs[4].get(), inputs[5].get(), inputs[6].get());
			
			if (mData != null) {
				if (curve.curveMesh != null) curve.curveMesh.remove();
				if (curve.data.material_refs != null && curve.data.material_refs.length > 0) {
					var materials = new haxe.ds.Vector<MaterialData>(curve.data.material_refs.length);
					var loaded = 0;
					for (i in 0...curve.data.material_refs.length) {
						Data.getMaterial(Scene.active.raw.name, curve.data.material_refs[i], function(mat: MaterialData) {
							materials[i] = mat;
							loaded++;
							if (loaded == curve.data.material_refs.length) {
								curve.curveMesh = new MeshObject(mData, materials);
								curve.curveMesh.name = curve.data.name + "_mesh";
								curve.curveMesh.raw = cast {
									name: curve.curveMesh.name,
									type: "mesh_object"
								};
								curve.curveMesh.setParent(curve);
								curve.curveMesh.addTrait(new armory.trait.internal.UniformsManager());
							}
						});
					}
				}
			}
		}

		runOutput(0);
	}
}