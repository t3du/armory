package iron.object;

import iron.data.SceneFormat;
import iron.math.Vec4;

import iron.data.MeshData;
import iron.data.MaterialData;
import kha.arrays.Float32Array;
import kha.arrays.Uint32Array;

class CurveObject extends Object {

	public var data: TCurveData;

	static var _p0 = new Vec4();
	static var _p1 = new Vec4();
	static var _p2 = new Vec4();
	static var _p3 = new Vec4();

	static var _v1 = new Vec4();
	static var _v2 = new Vec4();

	public function new(data: TCurveData) {
		super();
		this.data = data;
		//trace(data);
		draw();

		//var obj: Object = cast createMeshObject(data);
		//obj.setParent(iron.Scene.active.root);

	}

	public function getPoint(t: Float, splineIndex: Int = 0): Vec4 {
		if (data.splines == null || data.splines.length <= splineIndex) return new Vec4();
    
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

		return interpBezier(localT, _p0, _p1, _p2, _p3);
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
		var steps = 200;
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
		var steps = 200;
		var lastP = getPoint(0, splineIndex);
		for (i in 1...steps + 1) {
			var p = getPoint(i / steps, splineIndex);
			length += lastP.distanceTo(p);
			lastP = p;
		}
		return length;
	}

	public function draw(strength: Float = 0.005) {
		#if arm_debug
		armory.trait.internal.DebugDraw.notifyOnRender(function(draw: armory.trait.internal.DebugDraw) {
			draw.color = 0xffffffff;
			draw.strength = strength;

			var worldMat = this.transform.world;
			
			for (s in 0...data.splines.length) {
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
		#end
	}

	public function follow(obj: Object, t: Float, splineIndex: Int = 0, forwardAxis: String = "Y") {
		var pos = getPoint(t, splineIndex);
		pos.applymat4(this.transform.world);
		obj.transform.loc.setFrom(pos);

		switch (forwardAxis) {
			case "X": _v1.set(1, 0, 0);
			case "-X": _v1.set(-1, 0, 0);
			case "Y": _v1.set(0, 1, 0);
			case "-Y": _v1.set(0, -1, 0);
			case "Z": _v1.set(0, 0, 1);
			case "-Z": _v1.set(0, 0, -1);
		}

		_v2.setFrom(getTangent(t, splineIndex));
		_v2.applyQuat(this.transform.rot); 

		obj.transform.rot.fromTo(_v1, _v2);
		obj.transform.buildMatrix();
	}

}