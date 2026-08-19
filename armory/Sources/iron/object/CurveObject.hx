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

		if (this.data.shape_keys != null && this.data.shape_keys.length > 0)
			applyShapeKeys();
		
		if (this.data.material_refs != null && this.data.material_refs.length > 0)
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
				resolution: spline.resolution,
				material_index: spline.material_index
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

	public function getClosestPoint(target: Vec4, splineIndex: Int = 0): Float {
		var minD = 1e10;
		var bestT = 0.0;
		var spline = data.splines[splineIndex];
		var segments = spline.closed ? spline.points.length : spline.points.length - 1;
		var steps = equidistantSamples > 0 ? equidistantSamples : Std.int(spline.resolution * segments);
		if (steps < 1) steps = 1;
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

	public function getLength(splineIndex: Int = 0): Float {
		var length = 0.0;
		var lastP = getPoint(0, splineIndex);
		var spline = data.splines[splineIndex];
		var segments = spline.closed ? spline.points.length : spline.points.length - 1;
		var steps = equidistantSamples > 0 ? equidistantSamples : Std.int(spline.resolution * segments);
		if (steps < 1) steps = 1;
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

	public function generateBevelMesh(bevelDepth: Float = 0.05, bevelResolution: Int = 8, factorStart: Float = 0.0, factorEnd: Float = 1.0, fillCaps: Bool = false): MeshData {
		if (data.splines == null || splinesLength == 0)
			return null;

		var numSides = bevelResolution <= 0 ? 4 : (bevelResolution * 2 + 4);

		var rawPositions: Array<Vec4> = [];
		var rawNormals: Array<Vec4> = [];
		var rawUVs: Array<Vec4> = [];
		var indicesByMaterial = new Map<Int, Array<Int>>();

		for (splineIndex in 0...splinesLength) {
			var spline = data.splines[splineIndex];
			var matIdx = spline.material_index != null ? spline.material_index : 0;
			if (!indicesByMaterial.exists(matIdx)) indicesByMaterial.set(matIdx, []);
			var indices = indicesByMaterial.get(matIdx);

			var segments = spline.closed ? spline.points.length : spline.points.length - 1;
			var totalSteps = equidistantSamples > 0 ? equidistantSamples : Std.int(spline.resolution * segments);
			if (totalSteps < 1) totalSteps = 1;

			var startStep = Std.int(totalSteps * Math.max(0.0, Math.min(1.0, factorStart)));
			var endStep = Std.int(totalSteps * Math.max(0.0, Math.min(1.0, factorEnd)));
			var isClosedLoop = spline.closed && factorStart == 0.0 && factorEnd == 1.0;
			var numRings = endStep - startStep + 1;
			if (numRings < 2) continue;

			var baseIndex = rawPositions.length;

			var tangent = getTangent(factorStart, splineIndex);
			if (spline.closed && (factorStart == 0.0 || factorStart == 1.0)) {
				var tIn = getTangent(1.0, splineIndex);
				var tOut = getTangent(0.0, splineIndex);
				tangent.set(tIn.x + tOut.x, tIn.y + tOut.y, tIn.z + tOut.z);
				tangent.normalize();
			}
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
				if (spline.closed && (t == 0.0 || t == 1.0)) {
					var tIn = getTangent(1.0, splineIndex);
					var tOut = getTangent(0.0, splineIndex);
					currTangent.set(tIn.x + tOut.x, tIn.y + tOut.y, tIn.z + tOut.z);
					currTangent.normalize();
				}

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

				for (r in 0...(numSides + 1)) {
					var idx = r % numSides;
					var angle = (idx / numSides) * Math.PI * 2.0;
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

					if (isClosedLoop && s == numRings - 1) {
						vPos = rawPositions[baseIndex + r].clone();
						dir = rawNormals[baseIndex + r].clone();
					}

					rawPositions.push(vPos);
					rawNormals.push(dir);
					rawUVs.push(new Vec4(t, r / numSides, 0));
				}
			}

			var stride = numSides + 1;
			for (s in 0...numRings) {
				var nextS = s + 1;
				if (s == numRings - 1) continue;

				for (r in 0...numSides) {
					var v0 = baseIndex + s * stride + r;
					var v1 = baseIndex + s * stride + r + 1;
					var v2 = baseIndex + nextS * stride + r;
					var v3 = baseIndex + nextS * stride + r + 1;

					indices.push(v0);
					indices.push(v2);
					indices.push(v1);

					indices.push(v1);
					indices.push(v2);
					indices.push(v3);
				}
			}

			var isPartial = factorStart > 0.0 || factorEnd < 1.0;
			if (fillCaps && (!spline.closed || isPartial)) {
				var tStart = factorStart;
				var startTangent = getTangent(tStart, splineIndex);
				var capStartNormal = new Vec4(-startTangent.x, -startTangent.y, -startTangent.z);

				var pStart = new Vec4(0, 0, 0);
				for (r in 0...numSides) {
					var pos = rawPositions[baseIndex + r];
					pStart.add(pos);
				}
				pStart.mult(1.0 / numSides);

				var capStartCenterIdx = rawPositions.length;
				rawPositions.push(pStart);
				rawNormals.push(capStartNormal);
				rawUVs.push(new Vec4(0.5, 0.5, 0));

				var capStartRingBase = rawPositions.length;
				for (r in 0...numSides) {
					var origIdx = baseIndex + r;
					var angle = (r / numSides) * Math.PI * 2.0;
					var u = 0.5 + 0.5 * Math.cos(angle);
					var v = 0.5 + 0.5 * Math.sin(angle);

					rawPositions.push(rawPositions[origIdx].clone());
					rawNormals.push(capStartNormal);
					rawUVs.push(new Vec4(u, v, 0));
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

				var lastRingBase = baseIndex + (numRings - 1) * stride;
				var pEnd = new Vec4(0, 0, 0);
				for (r in 0...numSides) {
					var pos = rawPositions[lastRingBase + r];
					pEnd.add(pos);
				}
				pEnd.mult(1.0 / numSides);

				var capEndCenterIdx = rawPositions.length;
				rawPositions.push(pEnd);
				rawNormals.push(capEndNormal);
				rawUVs.push(new Vec4(0.5, 0.5, 0));

				var capEndRingBase = rawPositions.length;
				for (r in 0...numSides) {
					var origIdx = lastRingBase + r;
					var angle = (r / numSides) * Math.PI * 2.0;
					var u = 0.5 + 0.5 * Math.cos(angle);
					var v = 0.5 + 0.5 * Math.sin(angle);

					rawPositions.push(rawPositions[origIdx].clone());
					rawNormals.push(capEndNormal);
					rawUVs.push(new Vec4(u, v, 0));
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

		var indexArrays: Array<TIndexArray> = [];
		for (matIdx in indicesByMaterial.keys()) {
			var matIndices = indicesByMaterial.get(matIdx);
			var inda = new Uint32Array(matIndices.length);
			for (i in 0...matIndices.length) inda.set(i, matIndices[i]);
			indexArrays.push({ material: matIdx, values: inda });
		}

		var pos: TVertexArray = { attrib: "pos", values: paa, data: "short4norm" };
		var nor: TVertexArray = { attrib: "nor", values: naa, data: "short2norm" };
		var tex: TVertexArray = { attrib: "tex", values: texa, data: "short2norm" };

		var rawmesh: TMeshData = {
			name: data.name + "_mesh",
			sorting_index: 0,
			vertex_arrays: [pos, nor, tex],
			index_arrays: indexArrays,
			scale_pos: maxdim
		};

		var md = new MeshData(rawmesh, function(d: MeshData) {});
		md.geom.calculateAABB();
		return md;
	}

	public function generateExtrudeMesh(width: Float = 0.1, thickness: Float = 0.1, factorStart: Float = 0.0, factorEnd: Float = 1.0, fillCaps: Bool = false): MeshData {
		if (data.splines == null || splinesLength == 0)
			return null;

		var rawPositions: Array<Vec4> = [];
		var rawNormals: Array<Vec4> = [];
		var rawUVs: Array<Vec4> = [];
		var indicesByMaterial = new Map<Int, Array<Int>>();

		var halfW = width * 0.5;
		var halfH = thickness * 0.5;

		for (splineIndex in 0...splinesLength) {
			var spline = data.splines[splineIndex];
			var matIdx = spline.material_index != null ? spline.material_index : 0;
			if (!indicesByMaterial.exists(matIdx)) indicesByMaterial.set(matIdx, []);
			var indices = indicesByMaterial.get(matIdx);

			var segments = spline.closed ? spline.points.length : spline.points.length - 1;
			var totalSteps = equidistantSamples > 0 ? equidistantSamples : Std.int(spline.resolution * segments);
			if (totalSteps < 1) totalSteps = 1;

			var startStep = Std.int(totalSteps * Math.max(0.0, Math.min(1.0, factorStart)));
			var endStep = Std.int(totalSteps * Math.max(0.0, Math.min(1.0, factorEnd)));
			var isClosedLoop = spline.closed && factorStart == 0.0 && factorEnd == 1.0;
			var numRings = endStep - startStep + 1;
			if (numRings < 2) continue;

			var baseIndex = rawPositions.length;

			var tangent = getTangent(factorStart, splineIndex);
			if (spline.closed && (factorStart == 0.0 || factorStart == 1.0)) {
				var tIn = getTangent(1.0, splineIndex);
				var tOut = getTangent(0.0, splineIndex);
				tangent.set(tIn.x + tOut.x, tIn.y + tOut.y, tIn.z + tOut.z);
				tangent.normalize();
			}
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
				if (spline.closed && (t == 0.0 || t == 1.0)) {
					var tIn = getTangent(1.0, splineIndex);
					var tOut = getTangent(0.0, splineIndex);
					currTangent.set(tIn.x + tOut.x, tIn.y + tOut.y, tIn.z + tOut.z);
					currTangent.normalize();
				}

				var axisVec = new Vec4();
				axisVec.crossvecs(lastTangent, currTangent);
				var dot = Math.max(-1.0, Math.min(1.0, lastTangent.dot(currTangent)));
				if (axisVec.length() > 0.00001) {
					axisVec.normalize();
					var angle = Math.acos(dot);
					var q = new Quat();
					q.fromAxisAngle(axisVec, angle);
					normal.applyQuat(q);
					binormal.applyQuat(q);
				}
				lastTangent = currTangent;

				var dirW = normal;
				var dirH = binormal;

				var offsets = [
					new Vec4(-dirW.x * halfW - dirH.x * halfH, -dirW.y * halfW - dirH.y * halfH, -dirW.z * halfW - dirH.z * halfH),
					new Vec4( dirW.x * halfW - dirH.x * halfH,  dirW.y * halfW - dirH.y * halfH,  dirW.z * halfW - dirH.z * halfH),
					new Vec4( dirW.x * halfW + dirH.x * halfH,  dirW.y * halfW + dirH.y * halfH,  dirW.z * halfW + dirH.z * halfH),
					new Vec4(-dirW.x * halfW + dirH.x * halfH, -dirW.y * halfW + dirH.y * halfH, -dirW.z * halfW + dirH.z * halfH)
				];

				var normDirs = [
					new Vec4(-dirW.x, -dirW.y, -dirW.z),
					new Vec4( dirW.x,  dirW.y,  dirW.z),
					new Vec4( dirH.x,  dirH.y,  dirH.z),
					new Vec4(-dirH.x, -dirH.y, -dirH.z)
				];

				for (i in 0...5) {
					var idx = i % 4;
					rawPositions.push(new Vec4(p.x + offsets[idx].x, p.y + offsets[idx].y, p.z + offsets[idx].z));
					rawNormals.push(normDirs[idx]);
					rawUVs.push(new Vec4(t, i / 4.0, 0));
				}
			}

			for (s in 0...numRings) {
				var nextS = s + 1;
				if (s == numRings - 1) continue;

				for (i in 0...4) {
					var v0 = baseIndex + s * 5 + i;
					var v1 = baseIndex + s * 5 + i + 1;
					var v2 = baseIndex + nextS * 5 + i;
					var v3 = baseIndex + nextS * 5 + i + 1;

					indices.push(v0);
					indices.push(v2);
					indices.push(v1);

					indices.push(v1);
					indices.push(v2);
					indices.push(v3);
				}
			}

			var isPartial = factorStart > 0.0 || factorEnd < 1.0;
			if (fillCaps && (!spline.closed || isPartial)) {
				var tStart = factorStart;
				var startTangent = getTangent(tStart, splineIndex);
				var capStartNormal = new Vec4(-startTangent.x, -startTangent.y, -startTangent.z);

				var pStart = new Vec4(0, 0, 0);
				for (r in 0...4) {
					var pos = rawPositions[baseIndex + r];
					pStart.add(pos);
				}
				pStart.mult(0.25);

				var capStartCenterIdx = rawPositions.length;
				rawPositions.push(pStart);
				rawNormals.push(capStartNormal);
				rawUVs.push(new Vec4(0.5, 0.5, 0));

				var capStartRingBase = rawPositions.length;
				for (r in 0...4) {
					var origIdx = baseIndex + r;
					var angle = (r / 4.0) * Math.PI * 2.0;
					var u = 0.5 + 0.5 * Math.cos(angle);
					var v = 0.5 + 0.5 * Math.sin(angle);

					rawPositions.push(rawPositions[origIdx].clone());
					rawNormals.push(capStartNormal);
					rawUVs.push(new Vec4(u, v, 0));
				}

				for (r in 0...4) {
					var nextR = (r + 1) % 4;
					var v0 = capStartRingBase + r;
					var v1 = capStartRingBase + nextR;
					indices.push(capStartCenterIdx);
					indices.push(v1);
					indices.push(v0);
				}

				var tEnd = factorEnd;
				var endTangent = getTangent(tEnd, splineIndex);
				var capEndNormal = endTangent.clone();

				var lastRingBase = baseIndex + (numRings - 1) * 5;
				var pEnd = new Vec4(0, 0, 0);
				for (r in 0...4) {
					var pos = rawPositions[lastRingBase + r];
					pEnd.add(pos);
				}
				pEnd.mult(0.25);

				var capEndCenterIdx = rawPositions.length;
				rawPositions.push(pEnd);
				rawNormals.push(capEndNormal);
				rawUVs.push(new Vec4(0.5, 0.5, 0));

				var capEndRingBase = rawPositions.length;
				for (r in 0...4) {
					var origIdx = lastRingBase + r;
					var angle = (r / 4.0) * Math.PI * 2.0;
					var u = 0.5 + 0.5 * Math.cos(angle);
					var v = 0.5 + 0.5 * Math.sin(angle);

					rawPositions.push(rawPositions[origIdx].clone());
					rawNormals.push(capEndNormal);
					rawUVs.push(new Vec4(u, v, 0));
				}

				for (r in 0...4) {
					var nextR = (r + 1) % 4;
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

		var indexArrays: Array<TIndexArray> = [];
		for (matIdx in indicesByMaterial.keys()) {
			var matIndices = indicesByMaterial.get(matIdx);
			var inda = new Uint32Array(matIndices.length);
			for (i in 0...matIndices.length) inda.set(i, matIndices[i]);
			indexArrays.push({ material: matIdx, values: inda });
		}

		var pos: TVertexArray = { attrib: "pos", values: paa, data: "short4norm" };
		var nor: TVertexArray = { attrib: "nor", values: naa, data: "short2norm" };
		var tex: TVertexArray = { attrib: "tex", values: texa, data: "short2norm" };

		var rawmesh: TMeshData = {
			name: data.name + "_mesh",
			sorting_index: 0,
			vertex_arrays: [pos, nor, tex],
			index_arrays: indexArrays,
			scale_pos: maxdim
		};

		var md = new MeshData(rawmesh, function(d: MeshData) {});
		md.geom.calculateAABB();
		return md;
	}

	public function generateDeformedMesh(baseMesh: MeshData, splineIndex = -1, forwardAxis: String = "X", repetitions: Int, factorStart: Float = 0.0, factorEnd: Float = 1.0): MeshData {
		if (data.splines == null || splinesLength == 0 || baseMesh == null || repetitions <= 0)
			return null;

		var rawPositions: Array<Vec4> = [];
		var rawNormals: Array<Vec4> = [];
		var rawUVs: Array<Vec4> = [];
		var indicesByMaterial = new Map<Int, Array<Int>>();

		var baseRaw = baseMesh.raw;
		var basePos: Int16Array = null;
		var baseNor: Int16Array = null;
		var baseTex: Int16Array = null;
		
		for (va in baseRaw.vertex_arrays) {
			if (va.attrib == "pos") basePos = va.values;
			else if (va.attrib == "nor") baseNor = va.values;
			else if (va.attrib == "tex") baseTex = va.values;
		}

		if (basePos == null) return null;

		var baseVertCount = Std.int(basePos.length / 4);
		var baseScale = baseRaw.scale_pos;

		var minVal = 1e10;
		var maxVal = -1e10;
		var unpackedPos = new Array<Vec4>();
		var unpackedNor = new Array<Vec4>();
		var unpackedTex = new Array<Vec4>();

		for (i in 0...baseVertCount) {
			var px = (basePos.get(i * 4) / 32767) * baseScale;
			var py = (basePos.get(i * 4 + 1) / 32767) * baseScale;
			var pz = (basePos.get(i * 4 + 2) / 32767) * baseScale;
			unpackedPos.push(new Vec4(px, py, pz));

			var fval = 0.0;
			switch (forwardAxis) {
				case "X": fval = px;
				case "-X": fval = -px;
				case "Y": fval = py;
				case "-Y": fval = -py;
				case "Z": fval = pz;
				case "-Z": fval = -pz;
				default: fval = px;
			}

			if (fval < minVal) minVal = fval;
			if (fval > maxVal) maxVal = fval;

			if (baseNor != null) {
				var nx = baseNor.get(i * 2) / 32767;
				var ny = baseNor.get(i * 2 + 1) / 32767;
				var nz = basePos.get(i * 4 + 3) / 32767;
				unpackedNor.push(new Vec4(nx, ny, nz));
			} else {
				unpackedNor.push(new Vec4(0, 0, 1));
			}

			if (baseTex != null) {
				var tu = baseTex.get(i * 2) / 32767;
				var tv = baseTex.get(i * 2 + 1) / 32767;
				unpackedTex.push(new Vec4(tu, tv, 0));
			} else {
				unpackedTex.push(new Vec4(0, 0, 0));
			}
		}

		var sizeVal = maxVal - minVal;
		if (sizeVal <= 0.00001) sizeVal = 1.0;

		var startIdx = splineIndex == -1 ? 0 : splineIndex;
		var endIdx = splineIndex == -1 ? splinesLength : splineIndex + 1;

		for (sIdx in startIdx...endIdx) {
			var spline = data.splines[sIdx];
			var segments = spline.closed ? spline.points.length : spline.points.length - 1;
			var frameCount = equidistantSamples > 0 ? equidistantSamples : Std.int(spline.resolution * segments);
			var framesNor = new Array<Vec4>();
			var framesBin = new Array<Vec4>();
			var framesTan = new Array<Vec4>();

			var startTangent = getTangent(0.0, sIdx);
			if (spline.closed) {
				var tIn = getTangent(1.0, sIdx);
				var tOut = getTangent(0.0, sIdx);
				startTangent.set(tIn.x + tOut.x, tIn.y + tOut.y, tIn.z + tOut.z);
				startTangent.normalize();
			}

			var _z = new Vec4(0, 0, 1);
			if (Math.abs(startTangent.dot(_z)) > 0.9999) {
				_z.set(0, 1, 0);
			}
			var _r = new Vec4();
			_r.crossvecs(startTangent, _z).normalize();
			var _u = new Vec4();
			_u.crossvecs(_r, startTangent).normalize();

			var normal = new Vec4(-_r.x, -_r.y, -_r.z);
			var binormal = new Vec4(_u.x, _u.y, _u.z);

			var lastTangent = startTangent.clone();

			for (i in 0...frameCount + 1) {
				var t = i / frameCount;
				var currTangent = getTangent(t, sIdx);

				if (spline.closed && (t == 0.0 || t == 1.0)) {
					var tIn = getTangent(1.0, sIdx);
					var tOut = getTangent(0.0, sIdx);
					currTangent.set(tIn.x + tOut.x, tIn.y + tOut.y, tIn.z + tOut.z);
					currTangent.normalize();
				}

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
				lastTangent = currTangent.clone();

				framesNor.push(normal.clone());
				framesBin.push(binormal.clone());
				framesTan.push(currTangent.clone());
			}

			if (spline.closed) {
				var endDot = Math.max(-1.0, Math.min(1.0, framesNor[0].dot(framesNor[frameCount])));
				var endAngle = Math.acos(endDot);
				
				var crossTest = new Vec4();
				crossTest.crossvecs(framesNor[0], framesNor[frameCount]);
				if (framesTan[0].dot(crossTest) < 0) {
					endAngle = -endAngle;
				}
				
				for (i in 0...frameCount + 1) {
					var t = i / frameCount;
					var qFix = new Quat();
					qFix.fromAxisAngle(framesTan[i], -endAngle * t);
					framesNor[i].applyQuat(qFix);
					framesBin[i].applyQuat(qFix);
				}
			}

			for (rep in 0...repetitions) {
				var baseIndex = rawPositions.length;
				var repTStart = factorStart + (rep / repetitions) * (factorEnd - factorStart);
				var repTEnd = factorStart + ((rep + 1) / repetitions) * (factorEnd - factorStart);

				for (i in 0...baseVertCount) {
					var p = unpackedPos[i];
					var n = unpackedNor[i];
					var uv = unpackedTex[i];

					var fval = 0.0;
					var rval = 0.0;
					var uval = 0.0;
					var nfval = 0.0;
					var nrval = 0.0;
					var nuval = 0.0;

					switch (forwardAxis) {
						case "X":
							fval = p.x; rval = p.y; uval = p.z;
							nfval = n.x; nrval = n.y; nuval = n.z;
						case "-X":
							fval = -p.x; rval = -p.y; uval = p.z;
							nfval = -n.x; nrval = -n.y; nuval = n.z;
						case "Y":
							fval = p.y; rval = -p.x; uval = p.z;
							nfval = n.y; nrval = -n.x; nuval = n.z;
						case "-Y":
							fval = -p.y; rval = p.x; uval = p.z;
							nfval = -n.y; nrval = n.x; nuval = n.z;
						case "Z":
							fval = p.z; rval = -p.x; uval = -p.y;
							nfval = n.z; nrval = -n.x; nuval = -n.y;
						case "-Z":
							fval = -p.z; rval = -p.x; uval = p.y;
							nfval = -n.z; nrval = -n.x; nuval = n.y;
						default:
							fval = p.x; rval = p.y; uval = p.z;
							nfval = n.x; nrval = n.y; nuval = n.z;
					}

					var localT = (fval - minVal) / sizeVal;
					var curveT = repTStart + localT * (repTEnd - repTStart);

					if (curveT < 0) curveT = 0;
					if (curveT > 1) curveT = 1;

					var fIdx = curveT * frameCount;
					var i0 = Std.int(fIdx);
					var i1 = i0 + 1;
					if (i1 > frameCount) i1 = frameCount;
					var blend = fIdx - i0;

					var n0 = framesNor[i0];
					var n1 = framesNor[i1];
					var b0 = framesBin[i0];
					var b1 = framesBin[i1];
					var t0 = framesTan[i0];
					var t1 = framesTan[i1];

					var normalVec = new Vec4(
						n0.x + (n1.x - n0.x) * blend,
						n0.y + (n1.y - n0.y) * blend,
						n0.z + (n1.z - n0.z) * blend
					);
					normalVec.normalize();

					var binormalVec = new Vec4(
						b0.x + (b1.x - b0.x) * blend,
						b0.y + (b1.y - b0.y) * blend,
						b0.z + (b1.z - b0.z) * blend
					);
					binormalVec.normalize();

					var tangentVec = new Vec4(
						t0.x + (t1.x - t0.x) * blend,
						t0.y + (t1.y - t0.y) * blend,
						t0.z + (t1.z - t0.z) * blend
					);
					tangentVec.normalize();

					var curvePos = getPoint(curveT, sIdx);

					var finalPos = new Vec4(
						curvePos.x + normalVec.x * rval + binormalVec.x * uval,
						curvePos.y + normalVec.y * rval + binormalVec.y * uval,
						curvePos.z + normalVec.z * rval + binormalVec.z * uval
					);

					var finalNor = new Vec4(
						normalVec.x * nrval + binormalVec.x * nuval + tangentVec.x * nfval,
						normalVec.y * nrval + binormalVec.y * nuval + tangentVec.y * nfval,
						normalVec.z * nrval + binormalVec.z * nuval + tangentVec.z * nfval
					);
					finalNor.normalize();

					rawPositions.push(finalPos);
					rawNormals.push(finalNor);
					rawUVs.push(new Vec4(uv.x, uv.y, 0));
				}

				for (ia in baseRaw.index_arrays) {
					var mat = ia.material;
					if (!indicesByMaterial.exists(mat)) indicesByMaterial.set(mat, []);
					var destIndices = indicesByMaterial.get(mat);
					var srcIndices = ia.values;

					for (i in 0...srcIndices.length) {
						destIndices.push(baseIndex + srcIndices.get(i));
					}
				}
			}
		}

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

		var indexArrays: Array<TIndexArray> = [];
		for (matIdx in indicesByMaterial.keys()) {
			var matIndices = indicesByMaterial.get(matIdx);
			var inda = new Uint32Array(matIndices.length);
			for (i in 0...matIndices.length) inda.set(i, matIndices[i]);
			indexArrays.push({ material: matIdx, values: inda });
		}

		var posVA: TVertexArray = { attrib: "pos", values: paa, data: "short4norm" };
		var norVA: TVertexArray = { attrib: "nor", values: naa, data: "short2norm" };
		var texVA: TVertexArray = { attrib: "tex", values: texa, data: "short2norm" };

		var rawmesh: TMeshData = {
			name: data.name + "_mesh",
			sorting_index: 0,
			vertex_arrays: [posVA, norVA, texVA],
			index_arrays: indexArrays,
			scale_pos: maxdim
		};

		var md = new MeshData(rawmesh, function(d: MeshData) {});
		md.geom.calculateAABB();
		return md;
	}
}