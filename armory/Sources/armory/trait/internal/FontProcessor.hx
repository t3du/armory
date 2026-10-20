package armory.trait.internal;

import iron.math.Vec4;
import iron.data.Data;
import kha.Blob;
import kha.graphics2.truetype.StbTruetype;
import kha.graphics2.truetype.StbTruetype.Stbtt_fontinfo;
import kha.graphics2.truetype.StbTruetype.Stbtt_vertex;
import haxe.ds.Vector;

class FontProcessor {
	public var info(default, null): Stbtt_fontinfo;

	public function new(info: Stbtt_fontinfo) {
		this.info = info;
	}

	public static function load(file: String, callback: FontProcessor->Void): Void {
		Data.getBlob(file, function(blob: Blob) {
			var info = new Stbtt_fontinfo();
			if (!StbTruetype.stbtt_InitFont(info, blob, 0)) {
				callback(null);
				return;
			}
			if (info.fdselect != null && info.fdselect.data == null) info.fdselect.data = Blob.alloc(0);
			callback(new FontProcessor(info));
		});
	}

	public function getGlyphIndex(code: Int): Int {
		return StbTruetype.stbtt_FindGlyphIndex(info, code);
	}

	public function getAdvanceWidth(code: Int): Int {
		var glyph = getGlyphIndex(code);
		return StbTruetype.stbtt_GetGlyphHMetrics(info, glyph).advanceWidth;
	}

	public function getGlyphContours(code: Int, curveSteps: Int): Array<Array<Vec4>> {
		var vertices = StbTruetype.stbtt_GetGlyphShape(info, getGlyphIndex(code));
		if (vertices == null || vertices.length == 0) return [];
		return flattenGlyph(vertices, curveSteps);
	}

	public function flattenGlyph(vertices: Vector<Stbtt_vertex>, curveSteps: Int): Array<Array<Vec4>> {
		var contours: Array<Array<Vec4>> = [];
		var contour: Array<Vec4> = null;
		var x = 0.0;
		var y = 0.0;
		for (i in 0...vertices.length) {
			var v = vertices[i];
			switch (v.type) {
				case StbTruetype.STBTT_vmove:
					closeContour(contours, contour);
					contour = [];
					x = v.x;
					y = v.y;
					contour.push(new Vec4(x, y));
				case StbTruetype.STBTT_vline:
					x = v.x;
					y = v.y;
					if (contour != null) contour.push(new Vec4(x, y));
				case StbTruetype.STBTT_vcurve:
					var ox = x;
					var oy = y;
					var steps = curveSteps < 2 ? 2 : curveSteps;
					for (step in 1...steps + 1) {
						var t = step / steps;
						var mt = 1 - t;
						contour.push(new Vec4(mt * mt * ox + 2 * mt * t * v.cx + t * t * v.x, mt * mt * oy + 2 * mt * t * v.cy + t * t * v.y));
					}
					x = v.x;
					y = v.y;
				case StbTruetype.STBTT_vcubic:
					var ox = x;
					var oy = y;
					var steps = curveSteps < 2 ? 2 : curveSteps;
					for (step in 1...steps + 1) {
						var t = step / steps;
						var mt = 1 - t;
						contour.push(new Vec4(mt * mt * mt * ox + 3 * mt * mt * t * v.cx + 3 * mt * t * t * v.cx1 + t * t * t * v.x, mt * mt * mt * oy + 3 * mt * mt * t * v.cy + 3 * mt * t * t * v.cy1 + t * t * t * v.y));
					}
					x = v.x;
					y = v.y;
			}
		}
		closeContour(contours, contour);
		return contours;
	}

	public function triangulate(contours: Array<Array<Vec4>>, reverse: Bool): Array<Float> {
		var triangles: Array<Float> = [];
		var ys: Array<Float> = [];
		var edges: Array<{a: Vec4, b: Vec4}> = [];
		for (contour in contours) for (i in 0...contour.length - 1) {
			var a = contour[i];
			var b = contour[i + 1];
			if (a.y == b.y) continue;
			edges.push({a: a, b: b});
			ys.push(a.y);
			ys.push(b.y);
		}
		ys.sort((a, b) -> a < b ? -1 : (a > b ? 1 : 0));
		var unique: Array<Float> = [];
		for (y in ys) if (unique.length == 0 || unique[unique.length - 1] != y) unique.push(y);
		for (band in 0...unique.length - 1) {
			var y0 = unique[band];
			var y1 = unique[band + 1];
			if (y1 - y0 < 0.0001) continue;
			var mid = (y0 + y1) * 0.5;
			var active: Array<{a: Vec4, b: Vec4, x: Float}> = [];
			for (edge in edges) {
				if (mid <= Math.min(edge.a.y, edge.b.y) || mid >= Math.max(edge.a.y, edge.b.y)) continue;
				active.push({a: edge.a, b: edge.b, x: xAt(edge.a, edge.b, mid)});
			}
			active.sort((a, b) -> a.x < b.x ? -1 : (a.x > b.x ? 1 : 0));
			var pair = 0;
			while (pair + 1 < active.length) {
				var l = active[pair];
				var r = active[pair + 1];
				var lx0 = xAt(l.a, l.b, y0);
				var lx1 = xAt(l.a, l.b, y1);
				var rx0 = xAt(r.a, r.b, y0);
				var rx1 = xAt(r.a, r.b, y1);
				if (Math.max(rx0 - lx0, rx1 - lx1) > 0.0001) {
					if (reverse) {
						pushTriangle(triangles, lx0, y0, rx1, y1, rx0, y0);
						pushTriangle(triangles, lx0, y0, lx1, y1, rx1, y1);
					}
					else {
						pushTriangle(triangles, lx0, y0, rx0, y0, rx1, y1);
						pushTriangle(triangles, lx0, y0, rx1, y1, lx1, y1);
					}
				}
				pair += 2;
			}
		}
		return triangles;
	}

	function closeContour(contours: Array<Array<Vec4>>, contour: Array<Vec4>) {
		if (contour == null || contour.length < 3) return;
		var a = contour[0];
		var b = contour[contour.length - 1];
		if (a.x != b.x || a.y != b.y) contour.push(new Vec4(a.x, a.y));
		contours.push(contour);
	}

	inline function xAt(a: Vec4, b: Vec4, y: Float): Float {
		return a.x + (y - a.y) * (b.x - a.x) / (b.y - a.y);
	}

	inline function pushTriangle(target: Array<Float>, x0: Float, y0: Float, x1: Float, y1: Float, x2: Float, y2: Float) {
		target.push(x0);
		target.push(y0);
		target.push(x1);
		target.push(y1);
		target.push(x2);
		target.push(y2);
	}
}
