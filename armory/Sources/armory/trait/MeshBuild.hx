package armory.trait;

import iron.Trait;
import iron.object.MeshObject;
import iron.system.Time;

class MeshBuild extends Trait {

	@prop
	public var startFrame: Float = 1.0;

	@prop
	public var length: Float = 100.0;

	@prop
	public var reversed: Bool = false;

	@prop
	public var randomize: Bool = false;

	var mesh: MeshObject;
	var totalTris: Int = 0;
	var totalFaces: Int = 0;
	var totalIndices: Int = 0;
	var elapsedFrames: Float = 0.0;
	var isRunning: Bool = true;

	var origIndices: Array<Int> = [];
	var faceOrder: Array<Int> = [];

	public function new() {
		super();
		notifyOnAdd(init);
	}

	function init() {
		mesh = cast(object, MeshObject);
		if (mesh == null || mesh.data == null || mesh.data.geom == null) return;

		totalTris = mesh.data.geom.numTris;
		totalIndices = totalTris * 3;
		totalFaces = Std.int(Math.ceil(totalTris / 2));

		if (mesh.data.geom.indexBuffers.length > 0) {
			var ib = mesh.data.geom.indexBuffers[0];
			var locked = ib.lock();

			for (i in 0...totalIndices) {
				origIndices.push(locked[i]);
			}

			for (i in 0...totalFaces) {
				faceOrder.push(i);
			}

			if (randomize) {
				for (i in 0...totalFaces) {
					var r = Std.int(Math.random() * totalFaces);
					var temp = faceOrder[i];
					faceOrder[i] = faceOrder[r];
					faceOrder[r] = temp;
				}
			}

			ib.unlock();
		}

		mesh.data.geom.count = reversed ? totalIndices : 0;
		notifyOnUpdate(update);
	}

	function update() {
		if (!isRunning) return;

		elapsedFrames += Time.delta * 60.0;

		if (elapsedFrames < startFrame) return;

		var rawProgress = (elapsedFrames - startFrame) / length;
		var finished = false;

		if (rawProgress >= 1.0) {
			rawProgress = 1.0;
			finished = true;
			isRunning = false;
		}

		var progress = reversed ? (1.0 - rawProgress) : rawProgress;
		var targetFaces = Std.int(progress * totalFaces);

		if (mesh.data.geom.indexBuffers.length > 0) {
			var ib = mesh.data.geom.indexBuffers[0];
			var indicesA = ib.lock();

			var writeIdx = 0;
			for (f in 0...targetFaces) {
				var faceIdx = faceOrder[f];
				var startTri = faceIdx * 2;

				if (startTri * 3 < totalIndices) {
					indicesA[writeIdx] = origIndices[startTri * 3];
					indicesA[writeIdx + 1] = origIndices[startTri * 3 + 1];
					indicesA[writeIdx + 2] = origIndices[startTri * 3 + 2];
					writeIdx += 3;
				}

				if ((startTri + 1) * 3 < totalIndices) {
					indicesA[writeIdx] = origIndices[(startTri + 1) * 3];
					indicesA[writeIdx + 1] = origIndices[(startTri + 1) * 3 + 1];
					indicesA[writeIdx + 2] = origIndices[(startTri + 1) * 3 + 2];
					writeIdx += 3;
				}
			}

			ib.unlock();
			mesh.data.geom.count = writeIdx;
		}

		if (finished && !reversed) {
			if (mesh.data.geom.indexBuffers.length > 0) {
				var ib = mesh.data.geom.indexBuffers[0];
				var indicesA = ib.lock();
				for (i in 0...totalIndices) {
					indicesA[i] = origIndices[i];
				}
				ib.unlock();
				mesh.data.geom.count = totalIndices;
			}
		}
	}
}