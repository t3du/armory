package armory.logicnode;

import iron.math.Vec4;
import iron.object.Object;
import iron.object.MeshObject;

class SampleObjectPointsNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var object: Object = inputs[0].get();
		if (object == null) return null;

		var sampleCount: Int = inputs[1].get();
		if (sampleCount == null || sampleCount <= 0) sampleCount = 1;

		if (!Std.isOfType(object, MeshObject)) return null;
		var mesh = cast(object, MeshObject).data;
		if (mesh == null || mesh.geom == null || mesh.geom.indices == null) return null;

		var indices = mesh.geom.indices[0];
		var positions = mesh.geom.positions.values;

		var numTriangles = Math.floor(indices.length / 3);
		if (numTriangles == 0) return null;

		var hx = object.transform.scale.x * (1 / 32767);
		var hy = object.transform.scale.y * (1 / 32767);
		var hz = object.transform.scale.z * (1 / 32767);
		if (mesh.raw.scale_pos != null) {
			hx *= mesh.raw.scale_pos;
			hy *= mesh.raw.scale_pos;
			hz *= mesh.raw.scale_pos;
		}

		var result: Array<{ point: Vec4, normal: Vec4 }> = [];

		var a1 = 0.8191725133961645;
		var a2 = 0.6710436067037892;
		var a3 = 0.5497004779019703;

		var seed1 = Math.random();
		var seed2 = Math.random();
		var seed3 = Math.random();

		for (i in 0...sampleCount) {
			var triFrac = (seed1 + i * a1) % 1.0;
			var triIndex = Math.floor(triFrac * numTriangles) * 3;

			var iA = indices[triIndex];
			var iB = indices[triIndex + 1];
			var iC = indices[triIndex + 2];

			var vA = new Vec4(positions[iA * 4] * hx, positions[iA * 4 + 1] * hy, positions[iA * 4 + 2] * hz);
			var vB = new Vec4(positions[iB * 4] * hx, positions[iB * 4 + 1] * hy, positions[iB * 4 + 2] * hz);
			var vC = new Vec4(positions[iC * 4] * hx, positions[iC * 4 + 1] * hy, positions[iC * 4 + 2] * hz);

			var r1 = (seed2 + i * a2) % 1.0;
			var r2 = (seed3 + i * a3) % 1.0;
			var sqrtR1 = Math.sqrt(r1);
			var weightA = 1 - sqrtR1;
			var weightB = sqrtR1 * (1 - r2);
			var weightC = sqrtR1 * r2;

			var pointPos = new Vec4();
			pointPos.x = weightA * vA.x + weightB * vB.x + weightC * vC.x;
			pointPos.y = weightA * vA.y + weightB * vB.y + weightC * vC.y;
			pointPos.z = weightA * vA.z + weightB * vB.z + weightC * vC.z;
			pointPos.applyproj(object.transform.world);

			var edge1 = new Vec4(vB.x - vA.x, vB.y - vA.y, vB.z - vA.z);
			var edge2 = new Vec4(vC.x - vA.x, vC.y - vA.y, vC.z - vA.z);
			var normalVec = edge1.cross(edge2).normalize();
			normalVec.applyQuat(object.transform.rot);
			normalVec.normalize();

			result.push({ point: pointPos, normal: normalVec });
		}

		return result;
	}
}