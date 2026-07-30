package armory.math;

import iron.math.Vec4;

// https://github.com/whuop/hxNoise/blob/master/hxnoise/Perlin.hx
// The MIT License (MIT)

// Copyright (c) 2016 Kristian Brodal

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

class Perlin {
	//	Hash lookup defined by Ken Perlin
	private static var PERMUTATIONS:Array<Int> = [
		151, 160, 137,  91,  90,  15, 131,  13, 201,  95,  96,  53, 194, 233,   7, 225,
		140,  36, 103,  30,  69, 142,   8,  99,  37, 240,  21,  10,  23, 190,   6, 148,
		247, 120, 234,  75,   0,  26, 197,  62,  94, 252, 219, 203, 117,  35,  11,  32,
		 57, 177,  33,  88, 237, 149,  56,  87, 174,  20, 125, 136, 171, 168,  68, 175,
		 74, 165,  71, 134, 139,  48,  27, 166,  77, 146, 158, 231,  83, 111, 229, 122,
		 60, 211, 133, 230, 220, 105,  92,  41,  55,  46, 245,  40, 244, 102, 143,  54,
		 65,  25,  63, 161,   1, 216,  80,  73, 209,  76, 132, 187, 208,  89,  18, 169,
		200, 196, 135, 130, 116, 188, 159,  86, 164, 100, 109, 198, 173, 186,   3,  64,
		 52, 217, 226, 250, 124, 123,   5, 202,  38, 147, 118, 126, 255,  82,  85, 212,
		207, 206,  59, 227,  47,  16,  58,  17, 182, 189,  28,  42, 223, 183, 170, 213,
		119, 248, 152,   2,  44, 154, 163,  70, 221, 153, 101, 155, 167,  43, 172,   9,
		129,  22,  39, 253,  19,  98, 108, 110,  79, 113, 224, 232, 178, 185, 112, 104,
		218, 246,  97, 228, 251,  34, 242, 193, 238, 210, 144,  12, 191, 179, 162, 241,
		 81,  51, 145, 235, 249,  14, 239, 107,  49, 192, 214,  31, 181, 199, 106, 157,
		184,  84, 204, 176, 115, 121,  50,  45, 127,   4, 150, 254, 138, 236, 205,  93,
		222, 114,  67,  29,  24,  72, 243, 141, 128, 195,  78,  66, 215,  61, 156, 180
	];

	private static var P:Array<Int>;
	public var repeat(default, default):Int;

	public function new(repeat:Int = -1):Void {
		this.repeat = repeat;
		if (P == null) {
			P = [for (x in 0...512) PERMUTATIONS[x % 256]];
		}
	}

	public function perlin(x:Float, y:Float, z:Float):Float {
		if (this.repeat > 0) {
			x = x % repeat;
			y = y % repeat;
			z = z % repeat;
		}

		var xi:Int = Math.floor(x) & 255;
		var yi:Int = Math.floor(y) & 255;
		var zi:Int = Math.floor(z) & 255;

		var xf:Float = x - Math.ffloor(x);
		var yf:Float = y - Math.ffloor(y);
		var zf:Float = z - Math.ffloor(z);

		var u:Float = fade(xf);
		var v:Float = fade(yf);
		var w:Float = fade(zf);

		var aaa, aba, aab, abb, baa, bba, bab, bbb:Int;
		aaa = P[P[P[xi] + yi] + zi];
		aba = P[P[P[xi] + inc(yi)] + zi];
		aab = P[P[P[xi] + yi] + inc(zi)];
		abb = P[P[P[xi] + inc(yi)] + inc(zi)];
		baa = P[P[P[inc(xi)] + yi] + zi];
		bba = P[P[P[inc(xi)] + inc(yi)] + zi];
		bab = P[P[P[inc(xi)] + yi] + inc(zi)];
		bbb = P[P[P[inc(xi)] + inc(yi)] + inc(zi)];

		var x1, x2, y1, y2:Float;
		x1 = lerp(grad(aaa, xf, yf, zf), grad(baa, xf - 1, yf, zf), u);
		x2 = lerp(grad(aba, xf, yf - 1, zf), grad(bba, xf - 1, yf - 1, zf), u);
		y1 = lerp(x1, x2, v);

		x1 = lerp(grad(aab, xf, yf, zf - 1), grad(bab, xf - 1, yf, zf - 1), u);
		x2 = lerp(grad(abb, xf, yf - 1, zf - 1), grad(bbb, xf - 1, yf - 1, zf - 1), u);
		y2 = lerp(x1, x2, v);

		return (lerp(y1, y2, w) + 1) / 2;
	}

	public function octavePerlin(x:Float, y:Float, z:Float, octaves:Int, persistence:Float, frequency:Float):Float {
		var total:Float = 0.0;
		var maxValue:Float = 0.0;
		var amplitude:Float = 1.0;

		for (i in 0...octaves) {
			total += perlin(x * frequency, y * frequency, z * frequency) * amplitude;
			maxValue += amplitude;

			amplitude *= persistence;
			frequency *= 2.0;
		}

		return total / maxValue;
	}

	public function fade(t:Float):Float {
		return t * t * t * (t * (t * 6 - 15) + 10);
	}

	public function inc(num:Int):Int {
		num++;
		if (repeat > 0) num %= repeat;
		return num;
	}

	public static function grad(hash:Int, x:Float, y:Float, z:Float):Float {
		var h:Int = hash & 15;
		var u:Float = h < 8 ? x : y;

		var v:Float;

		if (h < 4)
			v = y;
		else if (h == 12 || h == 14)
			v = x;
		else
			v = z;

		return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v);
	}

	public function lerp(a:Float, b:Float, x:Float):Float {
		return a + (x * (b - a));
	}
}

class DiamondSquare {
	private var m_values:Array<Float>;
	private var m_width:Int;
	private var m_height:Int;
	private var m_featureSize:Int;
	private var m_scale:Float;
	private var m_randFunc:Void->Float;

	public function new(width:Int, height:Int, featureSize:Int, scale:Float, randFunc:Void->Float):Void {
		m_width = width;
		m_height = height;
		m_featureSize = featureSize;
		m_scale = scale;
		m_randFunc = randFunc;

		var totalSize = m_width * m_height;
		m_values = new Array<Float>();
		for (i in 0...totalSize) {
			m_values.push(0.0);
		}

		var x = 0;
		while (x < m_width) {
			var y = 0;
			while (y < m_height) {
				setValue(x, y, m_randFunc());
				y += m_featureSize;
			}
			x += m_featureSize;
		}
	}

	public function sampleSquare(x:Int, y:Int, size:Int, value:Float):Void {
		var hs:Int = Math.floor(size / 2);

		var a = getValue(x - hs, y - hs);
		var b = getValue(x + hs, y - hs);
		var c = getValue(x - hs, y + hs);
		var d = getValue(x + hs, y + hs);

		setValue(x, y, ((a + b + c + d) / 4.0) + value);
	}

	public function sampleDiamond(x:Int, y:Int, size:Int, value:Float):Void {
		var hs:Int = Math.floor(size / 2);

		var a = getValue(x - hs, y);
		var b = getValue(x + hs, y);
		var c = getValue(x, y - hs);
		var d = getValue(x, y + hs);

		setValue(x, y, ((a + b + c + d) / 4.0) + value);
	}

	public function diamondSquare():Void {
		var stepSize:Int = m_featureSize;
		var scale:Float = m_scale;

		while (stepSize > 1) {
			var halfStep:Int = Math.floor(stepSize / 2.0);

			var y = halfStep;
			while (y < m_height) {
				var x = halfStep;
				while (x < m_width) {
					sampleSquare(x, y, stepSize, m_randFunc() * scale);
					x += stepSize;
				}
				y += stepSize;
			}

			y = 0;
			while (y < m_height) {
				var x = (y % stepSize == 0) ? halfStep : 0;
				while (x < m_width) {
					sampleDiamond(x, y, stepSize, m_randFunc() * scale);
					x += stepSize;
				}
				y += halfStep;
			}

			stepSize = Math.floor(stepSize / 2);
			scale /= 2.0;
		}
	}

	public function getValue(x:Int, y:Int):Float {
		x = wrap(x, m_width);
		y = wrap(y, m_height);
		return m_values[y * m_width + x];
	}

	public function setValue(x:Int, y:Int, value:Float):Void {
		x = wrap(x, m_width);
		y = wrap(y, m_height);
		m_values[y * m_width + x] = value;
	}

	private function wrap(v:Int, maxLength:Int):Int {
		var wrapped = v % (maxLength - 1);
		if (wrapped < 0) {
			wrapped += (maxLength - 1);
		}
		return wrapped;
	}
}

//source from https://gist.github.com/anissen/e27e1a769be7a46d550fecf7523bc9e2

// Adapated from java source by Herman Tulleken
// http://www.luma.co.za/labs/2008/02/27/poisson-disk-sampling/

// The algorithm is from the "Fast Poisson Disk Sampling in Arbitrary Dimensions" paper by Robert Bridson
// http://www.cs.ubc.ca/~rbridson/docs/bridson-siggraph07-poissondisk.pdf

// Code adapted from http://theinstructionlimit.com/fast-uniform-poisson-disk-sampling-in-c

typedef Settings = {
	TopLeft: Vec4,
	LowerRight: Vec4,
	Dimensions: Vec4,
	Center: Vec4,
	CellSize: Float,
	MinimumDistance: Float,
	RejectionSqDistance: Null<Float>,
	GridWidth: Int,
	GridHeight: Int,
	GridDepth: Int,
	Is3D: Bool
}

typedef State = {
	Grid: Array<Array<Array<Vec4>>>,
	ActivePoints: Array<Vec4>,
	Points: Array<Vec4>
}

class UniformPoissonSampler {
	static public var DefaultPointsPerIteration: Int = 30;
	static var SquareRootThree: Float = Math.sqrt(3);
	static var SquareRootTwo: Float = Math.sqrt(2);

	public static function SampleCube(topLeft: Vec4, lowerRight: Vec4, minimumDistance: Float, pointsPerIteration: Int = 30): Array<Vec4> {
		return Sample(topLeft, lowerRight, null, minimumDistance, pointsPerIteration, true);
	}

	public static function SampleSphere(center: Vec4, radius: Float, minimumDistance: Float, pointsPerIteration: Int = 30): Array<Vec4> {
		var topLeft = new Vec4(center.x - radius, center.y - radius, center.z - radius);
		var lowerRight = new Vec4(center.x + radius, center.y + radius, center.z + radius);
		return Sample(topLeft, lowerRight, radius, minimumDistance, pointsPerIteration, true);
	}

	public static function SampleRectangle(topLeft: Vec4, lowerRight: Vec4, minimumDistance: Float, pointsPerIteration: Int = 30): Array<Vec4> {
		return Sample(topLeft, lowerRight, null, minimumDistance, pointsPerIteration, false);
	}

	public static function SampleCircle(center: Vec4, radius: Float, minimumDistance: Float, pointsPerIteration: Int = 30): Array<Vec4> {
		var topLeft = new Vec4(center.x - radius, center.y - radius, center.z);
		var lowerRight = new Vec4(center.x + radius, center.y + radius, center.z);
		return Sample(topLeft, lowerRight, radius, minimumDistance, pointsPerIteration, false);
	}

	static function Sample(topLeft: Vec4, lowerRight: Vec4, rejectionDistance: Null<Float>, minimumDistance: Float, pointsPerIteration: Int, is3D: Bool): Array<Vec4> {
		var dimensions = new Vec4(lowerRight.x - topLeft.x, lowerRight.y - topLeft.y, lowerRight.z - topLeft.z);
		var cellSize = is3D ? minimumDistance / SquareRootThree : minimumDistance / SquareRootTwo;

		var settings: Settings = {
			TopLeft: topLeft,
			LowerRight: lowerRight,
			Dimensions: dimensions,
			Center: new Vec4((topLeft.x + lowerRight.x) / 2, (topLeft.y + lowerRight.y) / 2, (topLeft.z + lowerRight.z) / 2),
			CellSize: cellSize,
			MinimumDistance: minimumDistance,
			RejectionSqDistance: rejectionDistance == null ? null : rejectionDistance * rejectionDistance,
			GridWidth: Std.int((dimensions.x / cellSize) + 1),
			GridHeight: Std.int((dimensions.y / cellSize) + 1),
			GridDepth: is3D ? Std.int((dimensions.z / cellSize) + 1) : 1,
			Is3D: is3D
		};

		var grid = [];
		for (z in 0 ... settings.GridDepth) {
			var plane = [];
			for (y in 0 ... settings.GridHeight) {
				var row = [];
				for (x in 0 ... settings.GridWidth) {
					row.push(null);
				}
				plane.push(row);
			}
			grid.push(plane);
		}

		var state: State = {
			Grid: grid,
			ActivePoints: [],
			Points: []
		};

		AddFirstPoint(settings, state);

		while (state.ActivePoints.length != 0) {
			var ArrayIndex: Int = Math.floor(Math.random() * state.ActivePoints.length);

			var point = state.ActivePoints[ArrayIndex];
			var found = false;

			for (k in 0 ... pointsPerIteration) {
				if (AddNextPoint(point, settings, state)) found = true;
			}

			if (!found) state.ActivePoints.splice(ArrayIndex, 1);
		}

		return state.Points;
	}

	static function DistanceSquared(p1: Vec4, p2: Vec4) {
		var dx = p1.x - p2.x;
		var dy = p1.y - p2.y;
		var dz = p1.z - p2.z;
		return (dx * dx) + (dy * dy) + (dz * dz);
	}

	static function Distance(p1: Vec4, p2: Vec4) {
		return Math.sqrt(DistanceSquared(p1, p2));
	}

	static function AddFirstPoint(settings: Settings, state: State) {
		var added = false;
		while (!added) {
			var xr = settings.TopLeft.x + settings.Dimensions.x * Math.random();
			var yr = settings.TopLeft.y + settings.Dimensions.y * Math.random();
			var zr = settings.Is3D ? settings.TopLeft.z + settings.Dimensions.z * Math.random() : settings.TopLeft.z;

			var p = new Vec4(xr, yr, zr);

			if (settings.RejectionSqDistance != null && DistanceSquared(settings.Center, p) > settings.RejectionSqDistance)
				continue;
			added = true;

			var index = Denormalize(p, settings.TopLeft, settings.CellSize, settings.Is3D);

			state.Grid[Std.int(index.z)][Std.int(index.y)][Std.int(index.x)] = p;

			state.ActivePoints.push(p);
			state.Points.push(p);
		}
	}

	static function AddNextPoint(point: Vec4, settings: Settings, state: State): Bool {
		var found = false;
		var q = GenerateRandomAround(point, settings.MinimumDistance, settings.Is3D);

		if (q.x >= settings.TopLeft.x && q.x < settings.LowerRight.x &&
			q.y >= settings.TopLeft.y && q.y < settings.LowerRight.y &&
			(!settings.Is3D || (q.z >= settings.TopLeft.z && q.z < settings.LowerRight.z)) &&
			(settings.RejectionSqDistance == null || DistanceSquared(settings.Center, q) <= settings.RejectionSqDistance))
		{
			var qIndex = Denormalize(q, settings.TopLeft, settings.CellSize, settings.Is3D);
			var tooClose = false;

			for (i in Std.int(Math.max(0, qIndex.x - 2)) ... Std.int(Math.min(settings.GridWidth, qIndex.x + 3))){
				for (j in Std.int(Math.max(0, qIndex.y - 2)) ... Std.int(Math.min(settings.GridHeight, qIndex.y + 3))) {
					for (l in Std.int(Math.max(0, qIndex.z - 2)) ... Std.int(Math.min(settings.GridDepth, qIndex.z + 3))) {

						var neighbor = state.Grid[l][j][i];

						if (neighbor != null && Distance(neighbor, q) < settings.MinimumDistance) {
							tooClose = true;
							break;
						}
					}
					if (tooClose) break;
				}
				if (tooClose) break;
			}

			if (!tooClose) {
				found = true;
				state.ActivePoints.push(q);
				state.Points.push(q);
				state.Grid[Std.int(qIndex.z)][Std.int(qIndex.y)][Std.int(qIndex.x)] = q;
			}
		}
		return found;
	}

	static function GenerateRandomAround(center: Vec4, minimumDistance: Float, is3D: Bool): Vec4 {
		var radiusMin = minimumDistance;
		var radiusMax = minimumDistance * 2;
		var radius = radiusMin + (radiusMax - radiusMin) * Math.random();

		if (is3D) {
			var d1 = Math.random();
			var d2 = Math.random();
			var phi = Math.PI * 2 * d1;
			var theta = Math.acos(1 - 2 * d2);
			var sinTheta = Math.sin(theta);
			var x = radius * sinTheta * Math.cos(phi);
			var y = radius * sinTheta * Math.sin(phi);
			var z = radius * Math.cos(theta);
			return new Vec4(center.x + x, center.y + y, center.z + z);
		} else {
			var angle = Math.PI * 2 * Math.random();
			var x = radius * Math.cos(angle);
			var y = radius * Math.sin(angle);
			return new Vec4(center.x + x, center.y + y, center.z);
		}
	}

	static function Denormalize(point: Vec4, origin: Vec4, cellSize: Float, is3D: Bool): Vec4 {
		return new Vec4(
			(point.x - origin.x) / cellSize,
			(point.y - origin.y) / cellSize,
			is3D ? (point.z - origin.z) / cellSize : 0
		);
	}
}