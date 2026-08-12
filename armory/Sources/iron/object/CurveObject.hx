package iron.object;

import iron.Scene;
import iron.data.SceneFormat;
import iron.math.Vec4;
import iron.math.Quat;
import iron.math.Mat4;
import iron.data.Data;
import iron.data.MeshData;
import iron.data.MaterialData;
import haxe.ds.Vector;
import kha.arrays.Float32Array;
import kha.arrays.Uint32Array;
import kha.arrays.Int16Array;
import kha.Color;
import armory.trait.internal.RenderDraw;

class CurveObject extends Object {

	public var data: TCurveData;
	public var splinesLength: Int;
	public var equidistantSamples: Int = 0;
	public var curveMesh: MeshObject = null;

	static var _p0 = new Vec4();
	static var _p1 = new Vec4();
	static var _p2 = new Vec4();
	static var _p3 = new Vec4();

	static var _v1 = new Vec4();
	static var _v2 = new Vec4();

	public function new(data: TCurveData) {
		super();
		this.data = copyCurveData(data);
		splinesLength = this.data.splines.length;

		if (this.data.shape_keys != null && this.data.shape_keys.length > 0) {
			applyShapeKeys();
			var mData = generateMesh(0.05, 8);
			if (mData != null && this.data.material_refs != null && this.data.material_refs.length > 0)
				Data.getMaterial(Scene.active.raw.name, this.data.material_refs[0], function(mat: MaterialData) {
					var materials = new haxe.ds.Vector<MaterialData>(1);
					materials[0] = mat;
					curveMesh = new MeshObject(mData, materials);
					curveMesh.name = data.name + "_mesh";
					curveMesh.raw = cast {
						name: curveMesh.name,
						type: "mesh_object"
					};
					curveMesh.setParent(this);
					curveMesh.addTrait(new armory.trait.internal.UniformsManager());
				});
		}
		else if (this.data.material_refs != null && this.data.material_refs.length > 0)
			addMeshObject();
		else
			draw(this.data.strength, Color.fromFloats(this.data.color[0], this.data.color[1], this.data.color[2], this.data.color[3]));
	}

	public function addMeshObject(){
		Data.getMesh("mesh_" + data.name, data.name, function(meshData: MeshData) {
			var materials = new Vector<MaterialData>(data.material_refs.length);
			var materialsLoaded = 0;
			
			for (i in 0...data.material_refs.length) {
				var ref = data.material_refs[i];
				
				Data.getMaterial(Scene.active.raw.name, ref, function(mat: MaterialData) {
					materials[i] = mat;
					materialsLoaded++;

					if (materialsLoaded == data.material_refs.length) {
						curveMesh = new MeshObject(meshData, materials);
						curveMesh.name = this.data.object + "_mesh";
						curveMesh.raw = cast {
							name: this.data.object + "_mesh",
							type: "mesh_object",
							};
						curveMesh.setParent(this);
						curveMesh.addTrait(new armory.trait.internal.UniformsManager());
					}
				});
			}
		});	
	}

	public static function copyCurveData(data: TCurveData): TCurveData {
		var newData: TCurveData = {
			name: data.name,
			object: data.object,
			splines: [],
			strength: data.strength,
			color: copyFloat32Array(data.color),
			material_refs: data.material_refs,
			shape_keys: data.shape_keys
		};

		for (spline in data.splines) {
			var newSpline = {
				points: [],
				closed: spline.closed,
				resolution: spline.resolution
			};
			
			for (p in spline.points) {
				newSpline.points.push({
					co: copyFloat32Array(p.co),
					handle_left: copyFloat32Array(p.handle_left),
					handle_right: copyFloat32Array(p.handle_right)
				});
			}
			newData.splines.push(newSpline);
		}
		return newData;
	}

	public static function copyFloat32Array(arr: Float32Array): Float32Array {
		var newArr = new Float32Array(arr.length);
		for (i in 0...arr.length) newArr[i] = arr[i];
		return newArr;
	}

	public function getPoint(t: Float, splineIndex: Int = 0): Vec4 {
		if (data.splines == null || splinesLength <= splineIndex) return new Vec4();

		if (equidistantSamples <= 0) {
			return getBezierPoint(t, splineIndex);
		} 
		else {
			return getPointEquidistant(t, splineIndex, equidistantSamples);
		}
	}

	public function getBezierPoint(t: Float, splineIndex: Int = 0): Vec4 {
		if (data.splines == null || splinesLength <= splineIndex) return new Vec4();
		var spline = data.splines[splineIndex];
		var points = spline.points;
		if (points.length < 2) return new Vec4(points[0].co[0], points[0].co[1], points[0].co[2]);

		t = Math.max(0.0, Math.min(1.0, t));

		if (t >= 1.0) {
			var p = spline.closed ? points[0] : points[points.length - 1];
			return new Vec4(p.co[0], p.co[1], p.co[2]);
		}

		var numSegments = spline.closed ? points.length : points.length - 1;
		var progress = t * numSegments;
		var index = Std.int(progress);
		var localT = progress - index;

		var pK = points[index];
		var pK1 = (spline.closed && index == points.length - 1) ? points[0] : points[index + 1];

		_p0.set(pK.co[0], pK.co[1], pK.co[2]);
		_p1.set(pK.handle_right[0], pK.handle_right[1], pK.handle_right[2]);
		_p2.set(pK1.handle_left[0], pK1.handle_left[1], pK1.handle_left[2]);
		_p3.set(pK1.co[0], pK1.co[1], pK1.co[2]);

		if (spline.resolution == 12) {
			return interpBezier(localT, _p0, _p1, _p2, _p3);
		} else {
			var stepProgress = localT * spline.resolution;
			var stepIndex = Std.int(stepProgress);
			var stepT = stepProgress - stepIndex;

			var tA = stepIndex / spline.resolution;
			var tB = (stepIndex + 1) / spline.resolution;

			var pA = interpBezier(tA, _p0, _p1, _p2, _p3);
			var pB = interpBezier(tB, _p0, _p1, _p2, _p3);

			return new Vec4(
				pA.x + (pB.x - pA.x) * stepT,
				pA.y + (pB.y - pA.y) * stepT,
				pA.z + (pB.z - pA.z) * stepT
			);
		}
	}
	
	public function getPointEquidistant(t: Float, splineIndex: Int = 0, samples: Int = 100): Vec4 {
		if (data.splines == null || splinesLength <= splineIndex) return new Vec4();
		
		var spline = data.splines[splineIndex];
		
		var totalSteps = samples;
		if (spline.resolution != 12) {
			var numSegments = spline.closed ? spline.points.length : spline.points.length - 1;
			totalSteps = spline.resolution * numSegments;
			if (totalSteps < 1) totalSteps = 1;
		}

		var table = [0.0];
		var totalLength = 0.0;
		var lastP = getBezierPoint(0, splineIndex);

		for (i in 1...totalSteps + 1) {
			var p = getBezierPoint(i / totalSteps, splineIndex);
			totalLength += lastP.distanceTo(p);
			table.push(totalLength);
			lastP = p;
		}

		var targetDistance = Math.max(0.0, Math.min(1.0, t)) * totalLength;
		var low = 0;
		var high = table.length - 1;
		
		while (low < high - 1) {
			var mid = Std.int((low + high) / 2);
			if (table[mid] < targetDistance) low = mid;
			else high = mid;
		}

		var distStart = table[low];
		var distEnd = table[high];
		var segmentLength = distEnd - distStart;
		var localT = (segmentLength <= 0) ? 0 : (targetDistance - distStart) / segmentLength;
		var correctedT = (low + localT) / (table.length - 1);

		return getBezierPoint(correctedT, splineIndex);
	}

	function interpBezier(t: Float, p0: Vec4, p1: Vec4, p2: Vec4, p3: Vec4): Vec4 {
		var it = 1.0 - t;
		var b0 = it * it * it;
		var b1 = 3.0 * t * it * it;
		var b2 = 3.0 * t * t * it;
		var b3 = t * t * t;
		return new Vec4(
			p0.x * b0 + p1.x * b1 + p2.x * b2 + p3.x * b3,
			p0.y * b0 + p1.y * b1 + p2.y * b2 + p3.y * b3,
			p0.z * b0 + p1.z * b1 + p2.z * b2 + p3.z * b3
		);
	}

	public function getTangent(t: Float, splineIndex: Int = 0): Vec4 {
		var delta = 0.001;
		var t1 = Math.max(0.0, t - delta);
		var t2 = Math.min(1.0, t + delta);
		var p1 = getPoint(t1, splineIndex);
		var p2 = getPoint(t2, splineIndex);
		var tangent = new Vec4(p2.x - p1.x, p2.y - p1.y, p2.z - p1.z);
		tangent.normalize();
		return tangent;
	}

	public function getClosestPoint(target: Vec4, splineIndex: Int = 0, steps: Int = 200): Float {
		var minD = 1e10;
		var bestT = 0.0;
		for (i in 0...steps + 1) {
			var t = i / steps;
			var p = getPoint(t, splineIndex);
			var d = p.distanceTo(target);
			if (d < minD) {
				minD = d;
				bestT = t;
			}
		}
		return bestT;
	}

	public function getLength(splineIndex: Int = 0, steps: Int = 200): Float {
		var length = 0.0;
		var lastP = getPoint(0, splineIndex);
		for (i in 1...steps + 1) {
			var p = getPoint(i / steps, splineIndex);
			length += lastP.distanceTo(p);
			lastP = p;
		}
		return length;
	}

	public function draw(strength: Float = 0.005, color: kha.Color = Color.Black) {
		RenderDraw.notifyOnRender(function(draw: RenderDraw) {
			if (!visible) return;
			draw.color = color;
			draw.strength = strength;

			var worldMat = this.transform.world;
			
			for (s in 0...splinesLength) {
				var spline = data.splines[s];
				var segments = spline.closed ? spline.points.length : spline.points.length - 1;
				var totalSteps = spline.resolution * segments;
				var step = 1.0 / (totalSteps);
				for (i in 0...totalSteps) {
					var t1 = i * step;
					var t2 = (i + 1) * step;

					var p1 = getPoint(t1, s);
					var p2 = getPoint(t2, s);

					p1.applymat4(worldMat);
					p2.applymat4(worldMat);

					draw.linev(p1, p2);
				}
			}
		});
	}

	var _q = new Quat();
	var _m = Mat4.identity();
	var _f = new Vec4();
	var _r = new Vec4();
	var _u = new Vec4();
	var _z = new Vec4();
	var _vx = new Vec4();
	var _vy = new Vec4();
	var _vz = new Vec4();

	public function follow(obj: Object, t: Float, splineIndex: Int = 0, forwardAxis: String = "X") {
		var pos = getPoint(t, splineIndex);
		pos.applymat4(this.transform.world);
		obj.transform.loc.setFrom(pos);

		_f.setFrom(getTangent(t, splineIndex));
		_f.applyQuat(this.transform.rot);
		_f.normalize();

		_z.set(0, 0, 1);
		if (Math.abs(_f.dot(_z)) > 0.9999) {
			_z.set(0, 1, 0);
		}

		_r.crossvecs(_f, _z).normalize();
		_u.crossvecs(_r, _f).normalize();

		switch (forwardAxis) {
			case "X":
				_vx.setFrom(_f);
				_vy.set(-_r.x, -_r.y, -_r.z);
				_vz.setFrom(_u);
			case "-X":
				_vx.set(-_f.x, -_f.y, -_f.z);
				_vy.setFrom(_r);
				_vz.setFrom(_u);
			case "Y":
				_vx.setFrom(_r);
				_vy.setFrom(_f);
				_vz.setFrom(_u);
			case "-Y":
				_vx.set(-_r.x, -_r.y, -_r.z);
				_vy.set(-_f.x, -_f.y, -_f.z);
				_vz.setFrom(_u);
			case "Z":
				_vx.setFrom(_r);
				_vy.set(-_u.x, -_u.y, -_u.z);
				_vz.setFrom(_f);
			case "-Z":
				_vx.setFrom(_r);
				_vy.setFrom(_u);
				_vz.set(-_f.x, -_f.y, -_f.z);
		}

		_m._00 = _vx.x; _m._01 = _vx.y; _m._02 = _vx.z;
		_m._10 = _vy.x; _m._11 = _vy.y; _m._12 = _vy.z;
		_m._20 = _vz.x; _m._21 = _vz.y; _m._22 = _vz.z;

		_q.fromRotationMat(_m);
		obj.transform.rot.setFrom(_q);

		obj.transform.buildMatrix();
	}

	override public function remove() {
		visible = false;
		super.remove();
	}

	public function setShapeKey(name: String, value: Float) {
		if (data.shape_keys == null) return;
		for (key in data.shape_keys) {
			if (key.name == name) {
				key.value = value;
				break;
			}
		}
		applyShapeKeys();
	}

	public function applyShapeKeys() {
		var basis = data.shape_keys[0];

		for (s in 0...data.splines.length) {
			var spline = data.splines[s];
			for (i in 0...spline.points.length) {
				var pt = spline.points[i];
				var basisPt = basis.points[i];

				pt.co[0] = basisPt.co[0];
				pt.co[1] = basisPt.co[1];
				pt.co[2] = basisPt.co[2];

				pt.handle_left[0] = basisPt.handle_left[0];
				pt.handle_left[1] = basisPt.handle_left[1];
				pt.handle_left[2] = basisPt.handle_left[2];

				pt.handle_right[0] = basisPt.handle_right[0];
				pt.handle_right[1] = basisPt.handle_right[1];
				pt.handle_right[2] = basisPt.handle_right[2];

				for (k in 1...data.shape_keys.length) {
					var key = data.shape_keys[k];
					var val = key.value;
					if (val == 0) continue;

					var keyPt = key.points[i];

					pt.co[0] += (keyPt.co[0] - basisPt.co[0]) * val;
					pt.co[1] += (keyPt.co[1] - basisPt.co[1]) * val;
					pt.co[2] += (keyPt.co[2] - basisPt.co[2]) * val;

					pt.handle_left[0] += (keyPt.handle_left[0] - basisPt.handle_left[0]) * val;
					pt.handle_left[1] += (keyPt.handle_left[1] - basisPt.handle_left[1]) * val;
					pt.handle_left[2] += (keyPt.handle_left[2] - basisPt.handle_left[2]) * val;

					pt.handle_right[0] += (keyPt.handle_right[0] - basisPt.handle_right[0]) * val;
					pt.handle_right[1] += (keyPt.handle_right[1] - basisPt.handle_right[1]) * val;
					pt.handle_right[2] += (keyPt.handle_right[2] - basisPt.handle_right[2]) * val;
				}
			}
		}
	}

	public function generateMesh(bevelDepth: Float = 0.05, bevelResolution: Int = 8, factorStart: Float = 0.0, factorEnd: Float = 1.0, fillCaps: Bool = false): MeshData {
		if (data.splines == null || splinesLength == 0)
			return null;

		var numSides = bevelResolution <= 0 ? 4 : (bevelResolution * 2 + 4);

		var rawPositions: Array<Vec4> = [];
		var rawNormals: Array<Vec4> = [];
		var rawUVs: Array<Vec4> = [];
		var indices: Array<Int> = [];

		for (splineIndex in 0...splinesLength) {
			var spline = data.splines[splineIndex];

			var segments = spline.closed ? spline.points.length : spline.points.length - 1;
			var totalSteps = Std.int(spline.resolution * segments);
			if (totalSteps < 1) totalSteps = 1;

			var startStep = Std.int(totalSteps * Math.max(0.0, Math.min(1.0, factorStart)));
			var endStep = Std.int(totalSteps * Math.max(0.0, Math.min(1.0, factorEnd)));
			var numRings = endStep - startStep + 1;
			if (numRings < 2) continue;

			var baseIndex = rawPositions.length;

			var tangent = getTangent(factorStart, splineIndex);
			var normal = new Vec4(0, 1, 0);
			if (Math.abs(tangent.dot(normal)) > 0.9) normal.set(1, 0, 0);
			var binormal = new Vec4();
			binormal.crossvecs(tangent, normal);
			binormal.normalize();
			normal.crossvecs(binormal, tangent);
			normal.normalize();

			var lastTangent = tangent.clone();

			for (s in 0...numRings) {
				var stepIdx = startStep + s;
				var t = stepIdx / totalSteps;
				var p = getPoint(t, splineIndex);
				var currTangent = getTangent(t, splineIndex);

				var axis = new Vec4();
				axis.crossvecs(lastTangent, currTangent);
				var dot = Math.max(-1.0, Math.min(1.0, lastTangent.dot(currTangent)));
				if (axis.length() > 0.00001) {
					axis.normalize();
					var angle = Math.acos(dot);
					var q = new Quat();
					q.fromAxisAngle(axis, angle);
					normal.applyQuat(q);
					binormal.applyQuat(q);
				}
				lastTangent = currTangent;

				for (r in 0...numSides) {
					var angle = (r / numSides) * Math.PI * 2.0;
					var cosA = Math.cos(angle);
					var sinA = Math.sin(angle);

					var dir = new Vec4(
						normal.x * cosA + binormal.x * sinA,
						normal.y * cosA + binormal.y * sinA,
						normal.z * cosA + binormal.z * sinA
					);
					dir.normalize();

					var vPos = new Vec4(
						p.x + dir.x * bevelDepth,
						p.y + dir.y * bevelDepth,
						p.z + dir.z * bevelDepth
					);

					rawPositions.push(vPos);
					rawNormals.push(dir);
					rawUVs.push(new Vec4(t, r / numSides, 0));
				}
			}

			for (s in 0...(numRings - 1)) {
				for (r in 0...numSides) {
					var nextR = (r + 1) % numSides;
					var v0 = baseIndex + s * numSides + r;
					var v1 = baseIndex + s * numSides + nextR;
					var v2 = baseIndex + (s + 1) * numSides + r;
					var v3 = baseIndex + (s + 1) * numSides + nextR;

					indices.push(v0);
					indices.push(v2);
					indices.push(v1);

					indices.push(v1);
					indices.push(v2);
					indices.push(v3);
				}
			}

			var isPartial = factorStart > 0.0 || factorEnd < 1.0;
			if (fillCaps && (isPartial || !spline.closed)) {
				var tStart = factorStart;
				var startTangent = getTangent(tStart, splineIndex);
				var capStartNormal = new Vec4(-startTangent.x, -startTangent.y, -startTangent.z);
				var pStart = getPoint(tStart, splineIndex);

				var capStartCenterIdx = rawPositions.length;
				rawPositions.push(pStart);
				rawNormals.push(capStartNormal);
				rawUVs.push(new Vec4(0.5, 0.5, 0));

				var capStartRingBase = rawPositions.length;
				for (r in 0...numSides) {
					var origIdx = baseIndex + r;
					rawPositions.push(rawPositions[origIdx].clone());
					rawNormals.push(capStartNormal);
					rawUVs.push(new Vec4(0.5, 0.5, 0));
				}

				for (r in 0...numSides) {
					var nextR = (r + 1) % numSides;
					var v0 = capStartRingBase + r;
					var v1 = capStartRingBase + nextR;
					indices.push(capStartCenterIdx);
					indices.push(v1);
					indices.push(v0);
				}

				var tEnd = factorEnd;
				var endTangent = getTangent(tEnd, splineIndex);
				var capEndNormal = endTangent.clone();
				var pEnd = getPoint(tEnd, splineIndex);

				var capEndCenterIdx = rawPositions.length;
				rawPositions.push(pEnd);
				rawNormals.push(capEndNormal);
				rawUVs.push(new Vec4(0.5, 0.5, 0));

				var lastRingBase = baseIndex + (numRings - 1) * numSides;
				var capEndRingBase = rawPositions.length;
				for (r in 0...numSides) {
					var origIdx = lastRingBase + r;
					rawPositions.push(rawPositions[origIdx].clone());
					rawNormals.push(capEndNormal);
					rawUVs.push(new Vec4(0.5, 0.5, 0));
				}

				for (r in 0...numSides) {
					var nextR = (r + 1) % numSides;
					var v0 = capEndRingBase + r;
					var v1 = capEndRingBase + nextR;
					indices.push(capEndCenterIdx);
					indices.push(v0);
					indices.push(v1);
				}
			}
		}

		if (rawPositions.length == 0) return null;

		var maxdim = 0.0;
		for (p in rawPositions) {
			var ax = Math.abs(p.x);
			var ay = Math.abs(p.y);
			var az = Math.abs(p.z);
			if (ax > maxdim) maxdim = ax;
			if (ay > maxdim) maxdim = ay;
			if (az > maxdim) maxdim = az;
		}
		if (maxdim == 0) maxdim = 1.0;
		maxdim *= 2;
		var invdim = 1 / maxdim;

		var numVerts = rawPositions.length;
		var paa = new Int16Array(numVerts * 4);
		var naa = new Int16Array(numVerts * 2);
		var texa = new Int16Array(numVerts * 2);

		for (i in 0...numVerts) {
			var p = rawPositions[i];
			var n = rawNormals[i];
			var uv = rawUVs[i];

			paa.set(i * 4, Std.int(p.x * 32767 * invdim));
			paa.set(i * 4 + 1, Std.int(p.y * 32767 * invdim));
			paa.set(i * 4 + 2, Std.int(p.z * 32767 * invdim));
			naa.set(i * 2, Std.int(n.x * 32767));
			naa.set(i * 2 + 1, Std.int(n.y * 32767));
			paa.set(i * 4 + 3, Std.int(n.z * 32767));

			texa.set(i * 2, Std.int(uv.x * 32767));
			texa.set(i * 2 + 1, Std.int(uv.y * 32767));
		}

		var inda = new Uint32Array(indices.length);
		for (i in 0...indices.length) inda.set(i, indices[i]);

		var pos: TVertexArray = { attrib: "pos", values: paa, data: "short4norm" };
		var nor: TVertexArray = { attrib: "nor", values: naa, data: "short2norm" };
		var tex: TVertexArray = { attrib: "tex", values: texa, data: "short2norm" };
		var ind: TIndexArray = { material: 0, values: inda };

		var rawmesh: TMeshData = {
			name: data.name + "_generated_mesh",
			sorting_index: 0,
			vertex_arrays: [pos, nor, tex],
			index_arrays: [ind],
			scale_pos: maxdim
		};

		var md = new MeshData(rawmesh, function(d: MeshData) {});
		md.geom.calculateAABB();
		return md;
	}

	public function updateMesh(bevelDepth: Float = 0.05, bevelResolution: Int = 8, factorStart: Float = 0.0, factorEnd: Float = 1.0, fillCaps: Bool = false) {
		var mData = generateMesh(bevelDepth, bevelResolution, factorStart, factorEnd, fillCaps);
		if (mData != null) {
			var materials = (curveMesh != null) ? curveMesh.materials : null;
			if (curveMesh != null) curveMesh.remove();

			if (materials == null) return;

			curveMesh = new MeshObject(mData, materials);
			curveMesh.name = data.name + "_mesh";
			curveMesh.raw = cast {
				name: curveMesh.name,
				type: "mesh_object"
			};
			curveMesh.setParent(this);
			curveMesh.addTrait(new armory.trait.internal.UniformsManager());
		}
	}

}