package armory.logicnode;

import iron.object.CurveObject;
import iron.object.MeshObject;
import iron.data.Data;
import iron.data.MeshData;
import iron.data.MaterialData;
import iron.Scene;

class SetCurveMeshNode extends LogicNode {
	public var property0: String;

	var curve: CurveObject;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		curve = inputs[1].get();

		var mData: MeshData = null;

		switch(property0){
			case 'Extrude':
				mData = curve.generateExtrudeMesh(inputs[2].get(), inputs[3].get(), inputs[4].get(), inputs[5].get(), inputs[6].get());
			case 'Bevel':
				mData = curve.generateBevelMesh(inputs[2].get(), inputs[3].get(), inputs[4].get(), inputs[5].get(), inputs[6].get());
			case 'Deform':
				var mo: MeshObject = inputs[2].get();
				var repetitions: Int = Std.int(Math.max(inputs[4].get(), 1));
				mData = curve.generateDeformedMesh(mo.data, -1, inputs[3].get(), repetitions, inputs[5].get(), inputs[6].get());
				if (mData != null){
					if (curve.curveMesh != null) curve.curveMesh.remove();
					curve.curveMesh = new MeshObject(mData, mo.materials);
					curve.curveMesh.name = curve.data.name + "_mesh";
					curve.curveMesh.raw = cast {
						name: curve.curveMesh.name,
						type: "mesh_object"
					};
					curve.curveMesh.setParent(curve);
					curve.curveMesh.addTrait(new armory.trait.internal.UniformsManager());
				}
		}

		if (property0 != 'Deform' && mData != null) {
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

		runOutput(0);
	}

	override function get(from: Int): Dynamic {
		return curve != null ? curve.curveMesh : null;
	}
}