package armory.trait.internal;

import kha.graphics4.PipelineState;
import kha.graphics4.VertexStructure;
import kha.graphics4.VertexBuffer;
import kha.graphics4.IndexBuffer;
import kha.graphics4.VertexData;
import kha.graphics4.Usage;
import kha.graphics4.ConstantLocation;
import kha.graphics4.CompareMode;
import kha.graphics4.CullMode;
import kha.graphics4.BlendingFactor;
import iron.math.Vec4;
import iron.math.Mat4;
using armory.object.TransformExtension;

class RenderDraw {

	static var inst: RenderDraw = null;

	public var color: kha.Color = 0xff00ff00;
	public var strength = 0.05;

	var vertexBuffer: VertexBuffer;
	var indexBuffer: IndexBuffer;
	var pipeline: PipelineState;

	var vp: Mat4;
	var vpID: ConstantLocation;

	var vbData: kha.arrays.Float32Array;
	var ibData: kha.arrays.Uint32Array;

	static inline var maxLines = 300;
	static inline var maxVertices = maxLines * 4;
	static inline var maxIndices = maxLines * 6;
	var lines = 0;

	function new() {
		inst = this;

		var structure = new VertexStructure();
		structure.add("pos", VertexData.Float3);
		structure.add("col", VertexData.Float4);
		pipeline = new PipelineState();
		pipeline.inputLayout = [structure];
		#if arm_deferred
		pipeline.fragmentShader = kha.Shaders.render_line_deferred_frag;
		#else
		pipeline.fragmentShader = kha.Shaders.render_line_frag;
		#end
		pipeline.vertexShader = kha.Shaders.render_line_vert;

		pipeline.blendSource = BlendingFactor.SourceAlpha;
		pipeline.blendDestination = BlendingFactor.InverseSourceAlpha;
		pipeline.alphaBlendSource = BlendingFactor.SourceAlpha;
		pipeline.alphaBlendDestination = BlendingFactor.InverseSourceAlpha;

		pipeline.depthWrite = true;
		pipeline.depthMode = CompareMode.Less;
		pipeline.cullMode = CullMode.None;
		pipeline.compile();
		vpID = pipeline.getConstantLocation("ViewProjection");
		vp = Mat4.identity();

		vertexBuffer = new VertexBuffer(maxVertices, structure, Usage.DynamicUsage);
		indexBuffer = new IndexBuffer(maxIndices, Usage.DynamicUsage);
	}

	static var g: kha.graphics4.Graphics;

	public static function notifyOnRender(f: RenderDraw->Void): kha.graphics4.Graphics->Int->Int->Void {
		if (inst == null) inst = new RenderDraw();
		var cb = function(g4: kha.graphics4.Graphics, i: Int, len: Int) {
			g = g4;
			if (i == 0) inst.begin();
			f(inst);
			if (i == len - 1) inst.end();
		};
		iron.RenderPath.notifyOnContext("mesh", cb);
		return cb;
	}

	public static function removeOnRender(cb: kha.graphics4.Graphics->Int->Int->Void) {
		iron.RenderPath.removeNotifyOnContext("mesh", cb);
	}

	public function empty(transform: iron.object.Transform) {
		var scl = transform.scale;
		var loc = transform.getWorldPosition();
		var right = transform.world.right();
		var look = transform.world.look();
		var up = transform.world.up();

		var p1 = new Vec4(loc.x - right.x * scl.x, loc.y - right.y * scl.x, loc.z - right.z * scl.x);
		var p2 = new Vec4(loc.x + right.x * scl.x, loc.y + right.y * scl.x, loc.z + right.z * scl.x);
		linev(p1, p2);

		var p3 = new Vec4(loc.x - look.x * scl.y, loc.y - look.y * scl.y, loc.z - look.z * scl.y);
		var p4 = new Vec4(loc.x + look.x * scl.y, loc.y + look.y * scl.y, loc.z + look.z * scl.y);
		linev(p3, p4);

		var p5 = new Vec4(loc.x - up.x * scl.z, loc.y - up.y * scl.z, loc.z - up.z * scl.z);
		var p6 = new Vec4(loc.x + up.x * scl.z, loc.y + up.y * scl.z, loc.z + up.z * scl.z);
		linev(p5, p6);
	}

	public function light(transform: iron.object.Transform) {
		var segments = 12;
		var r = 0.3;
		var h = 2.0;

		var loc = transform.getWorldPosition();
		var right = transform.world.right();
		var look = transform.world.look();
		var up = transform.world.up();

		var bottom = new Vec4(
			loc.x - up.x * h,
			loc.y - up.y * h,
			loc.z - up.z * h
		);

		linev(loc, bottom);

		var prev = new Vec4();
		var first = new Vec4();

		for (i in 0...segments) {
			if (i % 2 != 0) continue;

			var angle1 = (i / segments) * Math.PI * 2;
			var angle2 = ((i + 1) / segments) * Math.PI * 2;

			var x1 = Math.cos(angle1) * r;
			var y1 = Math.sin(angle1) * r;
			var x2 = Math.cos(angle2) * r;
			var y2 = Math.sin(angle2) * r;

			var p1 = new Vec4(
				loc.x + right.x * x1 + look.x * y1,
				loc.y + right.y * x1 + look.y * y1,
				loc.z + right.z * x1 + look.z * y1
			);

			var p2 = new Vec4(
				loc.x + right.x * x2 + look.x * y2,
				loc.y + right.y * x2 + look.y * y2,
				loc.z + right.z * x2 + look.z * y2
			);

			linev(p1, p2);
		}
	}

	public function camera(transform: iron.object.Transform) {
		var scl = transform.scale;
		var d = 2.0 * scl.z;
		var w = 0.8 * scl.x;
		var h = 0.6 * scl.y;
		var th = 0.4 * scl.y;

		var loc = transform.getWorldPosition();
		var right = transform.world.right();
		var look = transform.world.look();
		var up = transform.world.up();

		var c1 = new Vec4(
			loc.x - up.x * d + right.x * w + look.x * h,
			loc.y - up.y * d + right.y * w + look.y * h,
			loc.z - up.z * d + right.z * w + look.z * h
		);
		var c2 = new Vec4(
			loc.x - up.x * d - right.x * w + look.x * h,
			loc.y - up.y * d - right.y * w + look.y * h,
			loc.z - up.z * d - right.z * w + look.z * h
		);
		var c3 = new Vec4(
			loc.x - up.x * d - right.x * w - look.x * h,
			loc.y - up.y * d - right.y * w - look.y * h,
			loc.z - up.z * d - right.z * w - look.z * h
		);
		var c4 = new Vec4(
			loc.x - up.x * d + right.x * w - look.x * h,
			loc.y - up.y * d + right.y * w - look.y * h,
			loc.z - up.z * d + right.z * w - look.z * h
		);

		var topPeak = new Vec4(
			loc.x - up.x * d + look.x * (h + th),
			loc.y - up.y * d + look.y * (h + th),
			loc.z - up.z * d + look.z * (h + th)
		);

		linev(loc, c1);
		linev(loc, c2);
		linev(loc, c3);
		linev(loc, c4);

		linev(c1, c2);
		linev(c2, c3);
		linev(c3, c4);
		linev(c4, c1);

		linev(c1, topPeak);
		linev(c2, topPeak);
	}

	public function speaker(transform: iron.object.Transform) {
		var segments = 8;
		var r1 = 0.4;
		var r2 = 0.2;
		var h1 = 0.2;
		var h2 = 0.2;

		var loc = transform.getWorldPosition();
		var right = transform.world.right();
		var look = transform.world.look();
		var up = transform.world.up();

		var prevBase = new Vec4();
		var prevMid = new Vec4();
		var prevTop = new Vec4();
		var firstBase = new Vec4();
		var firstMid = new Vec4();
		var firstTop = new Vec4();

		for (i in 0...segments) {
			var angle = (i / segments) * Math.PI * 2;
			var cos = Math.cos(angle);
			var sin = Math.sin(angle);

			var mx = cos * r2;
			var my = sin * r2;

			var bx = cos * r1;
			var by = sin * r1;

			var currTop = new Vec4(
				loc.x + right.x * mx + look.x * my + up.x * h1,
				loc.y + right.y * mx + look.y * my + up.y * h1,
				loc.z + right.z * mx + look.z * my + up.z * h1
			);

			var currMid = new Vec4(
				loc.x + right.x * mx + look.x * my,
				loc.y + right.y * mx + look.y * my,
				loc.z + right.z * mx + look.z * my
			);

			var currBase = new Vec4(
				loc.x + right.x * bx + look.x * by - up.x * h2,
				loc.y + right.y * bx + look.y * by - up.y * h2,
				loc.z + right.z * bx + look.z * by - up.z * h2
			);

			linev(currTop, currMid);
			linev(currMid, currBase);

			if (i > 0) {
				linev(prevBase, currBase);
				linev(prevMid, currMid);
				linev(prevTop, currTop);
			} else {
				firstBase.setFrom(currBase);
				firstMid.setFrom(currMid);
				firstTop.setFrom(currTop);
			}

			prevBase.setFrom(currBase);
			prevMid.setFrom(currMid);
			prevTop.setFrom(currTop);
		}

		linev(prevBase, firstBase);
		linev(prevMid, firstMid);
		linev(prevTop, firstTop);
	}
	static var wv1 = new iron.math.Vec4();
	static var wv2 = new iron.math.Vec4();
	static var wv3 = new iron.math.Vec4();
	static var we1 = new iron.math.Vec4();
	static var we2 = new iron.math.Vec4();
	static var wn = new iron.math.Vec4();
	public function wireframe(mesh: iron.object.MeshObject) {
		if (mesh == null || mesh.data == null) return;

		var geom = mesh.data.geom;
		var pos = geom.positions.values;
		var indices = geom.indices;
		var world = mesh.transform.world;
		var scl = mesh.data.scalePos / 32767;

		var edgeMap = new haxe.ds.StringMap<iron.math.Vec4>();

		for (indexArray in indices) {
			var i = 0;
			while (i < indexArray.length) {
				var i1 = indexArray[i];
				var i2 = indexArray[i + 1];
				var i3 = indexArray[i + 2];

				wv1.set(pos[i1 * 4], pos[i1 * 4 + 1], pos[i1 * 4 + 2]);
				wv2.set(pos[i2 * 4], pos[i2 * 4 + 1], pos[i2 * 4 + 2]);
				wv3.set(pos[i3 * 4], pos[i3 * 4 + 1], pos[i3 * 4 + 2]);
				
				we1.set(wv2.x - wv1.x, wv2.y - wv1.y, wv2.z - wv1.z);
				we2.set(wv3.x - wv1.x, wv3.y - wv1.y, wv3.z - wv1.z);
				
				wn.crossvecs(we1, we2);
				wn.normalize();

				var edgeIndices = [[i1, i2], [i2, i3], [i3, i1]];
				for (edge in edgeIndices) {
					var a = edge[0];
					var b = edge[1];
					var key = a < b ? a + "_" + b : b + "_" + a;
					
					if (edgeMap.exists(key)) {
						if (wn.dot(edgeMap.get(key)) < 0.99) {
							wv1.set(pos[a * 4] * scl, pos[a * 4 + 1] * scl, pos[a * 4 + 2] * scl).applymat4(world);
							wv2.set(pos[b * 4] * scl, pos[b * 4 + 1] * scl, pos[b * 4 + 2] * scl).applymat4(world);
							linev(wv1, wv2);
						}
						edgeMap.remove(key);
					} else {
						edgeMap.set(key, wn.clone());
					}
				}
				i += 3;
			}
		}

		for (key in edgeMap.keys()) {
			var v = key.split("_");
			var a = Std.parseInt(v[0]);
			var b = Std.parseInt(v[1]);
			wv1.set(pos[a * 4] * scl, pos[a * 4 + 1] * scl, pos[a * 4 + 2] * scl).applymat4(world);
			wv2.set(pos[b * 4] * scl, pos[b * 4 + 1] * scl, pos[b * 4 + 2] * scl).applymat4(world);
			linev(wv1, wv2);
		}
	}

	public function outline(mesh: iron.object.MeshObject) {
		if (mesh == null || mesh.data == null) return;

		var geom = mesh.data.geom;
		var pos = geom.positions.values;
		var indices = geom.indices;
		var world = mesh.transform.world;
		var scl = mesh.data.scalePos / 32767;

		var camera = iron.Scene.active.camera;
		cameraPos.setFrom(camera.transform.getWorldPosition());

		var faceIsFront = new Array<Bool>();
		var edgeToFace = new haxe.ds.StringMap<Int>();
		var edgesToDraw = new Array<Int>();

		for (matIndex in 0...indices.length) {
			var indexArray = indices[matIndex];
			var i = 0;
			var faceIdx = 0;

			while (i < indexArray.length) {
				var i1 = indexArray[i];
				var i2 = indexArray[i + 1];
				var i3 = indexArray[i + 2];

				wv1.set(pos[i1 * 4] * scl, pos[i1 * 4 + 1] * scl, pos[i1 * 4 + 2] * scl).applymat4(world);
				wv2.set(pos[i2 * 4] * scl, pos[i2 * 4 + 1] * scl, pos[i2 * 4 + 2] * scl).applymat4(world);
				wv3.set(pos[i3 * 4] * scl, pos[i3 * 4 + 1] * scl, pos[i3 * 4 + 2] * scl).applymat4(world);
				
				we1.set(wv2.x - wv1.x, wv2.y - wv1.y, wv2.z - wv1.z);
				we2.set(wv3.x - wv1.x, wv3.y - wv1.y, wv3.z - wv1.z);
				wn.crossvecs(we1, we2);

				viewVec.set(cameraPos.x - wv1.x, cameraPos.y - wv1.y, cameraPos.z - wv1.z);
				
				var isFront = wn.dot(viewVec) > 0;
				faceIsFront.push(isFront);

				var eIdx = [[i1, i2], [i2, i3], [i3, i1]];
				for (e in eIdx) {
					var v1x = Math.round(pos[e[0]*4] * 100);
					var v1y = Math.round(pos[e[0]*4+1] * 100);
					var v1z = Math.round(pos[e[0]*4+2] * 100);
					var v2x = Math.round(pos[e[1]*4] * 100);
					var v2y = Math.round(pos[e[1]*4+1] * 100);
					var v2z = Math.round(pos[e[1]*4+2] * 100);
					
					var key = v1x < v2x ? v1x+"_"+v1y+"_"+v1z+"_"+v2x+"_"+v2y+"_"+v2z : v2x+"_"+v2y+"_"+v2z+"_"+v1x+"_"+v1y+"_"+v1z;

					if (edgeToFace.exists(key)) {
						var otherFaceIdx = edgeToFace.get(key);

						if (faceIsFront[otherFaceIdx] != isFront) {
							edgesToDraw.push(e[0]);
							edgesToDraw.push(e[1]);
						}
						edgeToFace.remove(key);
					} else {
						edgeToFace.set(key, faceIdx);
					}
				}

				faceIdx++;
				i += 3;
			}
		}

		var j = 0;
		while (j < edgesToDraw.length) {
			var a = edgesToDraw[j];
			var b = edgesToDraw[j + 1];
			wv1.set(pos[a * 4] * scl, pos[a * 4 + 1] * scl, pos[a * 4 + 2] * scl).applymat4(world);
			wv2.set(pos[b * 4] * scl, pos[b * 4 + 1] * scl, pos[b * 4 + 2] * scl).applymat4(world);
			linev(wv1, wv2);
			j += 2;
		}
	}

	static var objPosition: Vec4;
	static var vx = new Vec4();
	static var vy = new Vec4();
	static var vz = new Vec4();
	public function bounds(transform: iron.object.Transform) {
		objPosition = transform.getWorldPosition();
		var dx = transform.dim.x / 2;
		var dy = transform.dim.y / 2;
		var dz = transform.dim.z / 2;

		var up = transform.world.up();
		var look = transform.world.look();
		var right = transform.world.right();
		up.normalize();
		look.normalize();
		right.normalize();

		vx.setFrom(right);
		vx.mult(dx);
		vy.setFrom(look);
		vy.mult(dy);
		vz.setFrom(up);
		vz.mult(dz);

		lineb(-1, -1, -1,  1, -1, -1);
		lineb(-1,  1, -1,  1,  1, -1);
		lineb(-1, -1,  1,  1, -1,  1);
		lineb(-1,  1,  1,  1,  1,  1);

		lineb(-1, -1, -1, -1,  1, -1);
		lineb(-1, -1,  1, -1,  1,  1);
		lineb( 1, -1, -1,  1,  1, -1);
		lineb( 1, -1,  1,  1,  1,  1);

		lineb(-1, -1, -1, -1, -1,  1);
		lineb(-1,  1, -1, -1,  1,  1);
		lineb( 1, -1, -1,  1, -1,  1);
		lineb( 1,  1, -1,  1,  1,  1);
	}

	static var v1 = new Vec4();
	static var v2 = new Vec4();
	static var t = new Vec4();
	function lineb(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {
		v1.setFrom(objPosition);
		t.setFrom(vx); t.mult(a); v1.add(t);
		t.setFrom(vy); t.mult(b); v1.add(t);
		t.setFrom(vz); t.mult(c); v1.add(t);

		v2.setFrom(objPosition);
		t.setFrom(vx); t.mult(d); v2.add(t);
		t.setFrom(vy); t.mult(e); v2.add(t);
		t.setFrom(vz); t.mult(f); v2.add(t);

		linev(v1, v2);
	}

	public inline function linev(v1: Vec4, v2: Vec4) {
		line(v1.x, v1.y, v1.z, v2.x, v2.y, v2.z);
	}

	static var v1c = new iron.math.Vec4();
	static var cameraPos = new iron.math.Vec4();
	static var lineVec = new iron.math.Vec4();
	static var viewVec = new iron.math.Vec4();
	static var perp = new iron.math.Vec4();
	static var corner1 = new iron.math.Vec4();
	static var corner2 = new iron.math.Vec4();
	static var corner3 = new iron.math.Vec4();
	static var corner4 = new iron.math.Vec4();

	public function line(x1: Float, y1: Float, z1: Float, x2: Float, y2: Float, z2: Float) {
		if (vbData == null) return;
		if (lines >= maxLines) { end(); begin(); }

		var camera = iron.Scene.active.camera;
		cameraPos.setFrom(camera.transform.getWorldPosition());

		v1c.set(x1, y1, z1, 1.0).applymat4(camera.VP);
		var dist1 = v1c.w;
		v1c.set(x2, y2, z2, 1.0).applymat4(camera.VP);
		var dist2 = v1c.w;

		lineVec.set(x2 - x1, y2 - y1, z2 - z1);
		lineVec.normalize();

		viewVec.set(cameraPos.x - x1, cameraPos.y - y1, cameraPos.z - z1);
		viewVec.normalize();

		perp.crossvecs(viewVec, lineVec);
		perp.normalize();

		var s1 = strength * dist1 * 0.01;
		var s2 = strength * dist2 * 0.01;

		var bias = 0.005; 
		var bX = viewVec.x * bias;
		var bY = viewVec.y * bias;
		var bZ = viewVec.z * bias;

		corner1.set(x1 + perp.x * s1 + bX, y1 + perp.y * s1 + bY, z1 + perp.z * s1 + bZ);
		corner2.set(x1 - perp.x * s1 + bX, y1 - perp.y * s1 + bY, z1 - perp.z * s1 + bZ);
		corner3.set(x2 - perp.x * s2 + bX, y2 - perp.y * s2 + bY, z2 - perp.z * s2 + bZ);
		corner4.set(x2 + perp.x * s2 + bX, y2 + perp.y * s2 + bY, z2 + perp.z * s2 + bZ);

		var i = lines * 28;
		addVbData(i, [corner1.x, corner1.y, corner1.z, color.R, color.G, color.B, color.A]);
		i += 7;
		addVbData(i, [corner2.x, corner2.y, corner2.z, color.R, color.G, color.B, color.A]);
		i += 7;
		addVbData(i, [corner3.x, corner3.y, corner3.z, color.R, color.G, color.B, color.A]);
		i += 7;
		addVbData(i, [corner4.x, corner4.y, corner4.z, color.R, color.G, color.B, color.A]);

		i = lines * 6;
		ibData[i] = lines * 4;
		ibData[i + 1] = lines * 4 + 1;
		ibData[i + 2] = lines * 4 + 2;
		ibData[i + 3] = lines * 4 + 2;
		ibData[i + 4] = lines * 4 + 3;
		ibData[i + 5] = lines * 4;

		lines++;
	}

	function begin() {
		lines = 0;
		vbData = vertexBuffer.lock();
		ibData = indexBuffer.lock();
	}

	function end() {
		vertexBuffer.unlock();
		indexBuffer.unlock();

		g.setVertexBuffer(vertexBuffer);
		g.setIndexBuffer(indexBuffer);
		g.setPipeline(pipeline);
		var camera = iron.Scene.active.camera;
		vp.setFrom(camera.V);
		vp.multmat(camera.P);
		g.setMatrix(vpID, vp.self);
		g.drawIndexedVertices(0, lines * 6);
	}

	inline function addVbData(i: Int, data: Array<Float>) {
		for (offset in 0...7) {
			vbData.set(i + offset, data[offset]);
		}
	}
}