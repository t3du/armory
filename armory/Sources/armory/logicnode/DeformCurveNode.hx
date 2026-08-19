package armory.logicnode;

import iron.object.CurveObject;
import iron.object.MeshObject;
import iron.data.MeshData;

class DeformCurveNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var mo: MeshObject = inputs[1].get();
		var curve: CurveObject = inputs[2].get();

		var mData: MeshData = curve.generateDeformedMesh(mo.data, inputs[3].get(), inputs[4].get(), 1, inputs[5].get(), inputs[6].get());
		
		if (mData != null){
			mo.setData(mData);
			mo.transform.scale.set(1, 1, 1);
			mo.transform.buildMatrix();
		}

		runOutput(0);
	}
}