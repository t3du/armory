package iron.object;

import iron.Scene;
import iron.data.Data;
import iron.data.MaterialData;
import iron.data.MeshData;
import iron.data.SceneFormat;
import iron.math.Vec4;
import armory.trait.internal.FontProcessor;
import armory.trait.internal.RenderDraw;
import kha.Color;
import kha.graphics2.truetype.StbTruetype;
import kha.arrays.Float32Array;
import kha.arrays.Int16Array;
import kha.arrays.Uint32Array;
import kha.graphics4.Graphics;
import haxe.ds.Vector;

class TextObject extends Object {
	public var fontFile: String = "font_default";
	public var text: String = "Text";
	public var worldScale: Float = 0.001;
	public var extrusionDepth: Float = 0;
	public var curveSteps: Int = 8;
	public var materials: Vector<MaterialData>;
	public var outlineColor: Color = 0xff000000;
	public var outlineStrength: Float = 0;
	public var textMesh: MeshObject;
	public var fill: Bool = true;

	static var nextMeshId = 0;
	var fontProcessor: FontProcessor;
	var renderCallback: Graphics->Int->Int->Void;
	var requestId = 0;
	var centerX = 0.0;
	var centerY = 0.0;
	var centerZ = 0.0;

	public function new(data: TTextData = null, materials: Vector<MaterialData> = null, materialRefs: Array<String> = null) {
		super();
		if (data != null) {
			text = data.body;
			fontFile = data.font_file;
			worldScale = 0.001 * data.size;
			extrusionDepth = data.extrude;
			curveSteps = data.resolution_u;
			fill = data.fill;
			outlineStrength = data.outline_strength;
			if (data.outline_color != null && data.outline_color.length >= 4) outlineColor = Color.fromFloats(data.outline_color[0], data.outline_color[1], data.outline_color[2], data.outline_color[3]);
		}
		this.materials = materials;
		if (materials != null || materialRefs == null || materialRefs.length == 0) generate();
		else loadMaterials(materialRefs);
	}

	function loadMaterials(refs: Array<String>) {
		var materials = new Vector<MaterialData>(refs.length);
		var loaded = 0;
		for (i in 0...refs.length) {
			Data.getMaterial(Scene.active.raw.name, refs[i], function(material: MaterialData) {
				materials[i] = material;
				if (++loaded == refs.length) {
					this.materials = materials;
					generate();
				}
			});
		}
	}

	public function generate(): Void {
		var request = ++requestId;
		if (textMesh != null) {
			textMesh.remove();
			textMesh = null;
		}
		fontProcessor = null;
		if (outlineStrength > 0) {
			if (renderCallback == null) renderCallback = RenderDraw.notifyOnRender(drawOutline);
		}
		else if (renderCallback != null) {
			RenderDraw.removeOnRender(renderCallback);
			renderCallback = null;
		}
		FontProcessor.load(fontFile, function(processor: FontProcessor) {
			if (request != requestId || processor == null || materials == null || materials.length == 0 || materials[0] == null) return;
			fontProcessor = processor;
			var side = materials.length > 1 && materials[1] != null ? materials[1] : materials[0];
			buildMesh(request, materials[0], extrusionDepth == 0 ? null : side);
		});
	}

	function buildMesh(request: Int, fill: MaterialData, side: MaterialData) {
		var caps: Array<Float> = [];
		var sides: Array<Float> = [];
		var cursorX = 0.0;
		for (i in 0...text.length) {
			var code = text.charCodeAt(i);
			if (code == 10) continue;
			var contours = fontProcessor.getGlyphContours(code, curveSteps);
			if (contours.length > 0) {
				if (this.fill) appendFill(contours, cursorX, 0.001, caps, false);
				if (extrusionDepth != 0) {
					if (this.fill) appendFill(contours, cursorX, -extrusionDepth, caps, true);
					buildSides(contours, cursorX, sides);
				}
			}
			cursorX += fontProcessor.getAdvanceWidth(code);
		}
		if (request != requestId || (caps.length < 9 && sides.length < 9)) return;
		var packed = packMesh(caps, sides);
		centerX = packed.centerX;
		centerY = packed.centerY;
		centerZ = packed.centerZ;
		var data = new MeshData(packed.raw, function(value: MeshData) {});
		data.geom.calculateAABB();
		data.geom.aabb.set(packed.width, packed.height, packed.depth);
		data.name = packed.raw.name;
		data.scalePos = packed.scale;
		var materials = new Vector<MaterialData>(extrusionDepth == 0 ? 1 : 2);
		materials[0] = fill;
		if (extrusionDepth != 0) materials[1] = side;
		textMesh = new MeshObject(data, materials);
		textMesh.name = packed.raw.name;
		var dimensions = new Float32Array(3);
		dimensions[0] = packed.width;
		dimensions[1] = packed.height;
		dimensions[2] = packed.depth;
		textMesh.raw = cast { type: "mesh_object", name: packed.raw.name, data_ref: packed.raw.name, dimensions: dimensions };
		textMesh.transform.dim.setFrom(data.geom.aabb);
		textMesh.transform.radius = 0.5 * Math.sqrt(dimensions[0] * dimensions[0] + dimensions[1] * dimensions[1] + dimensions[2] * dimensions[2]);
		textMesh.setParent(this);
		textMesh.transform.loc.set(0, 0, 0);
		textMesh.transform.buildMatrix();
		textMesh.addTrait(new armory.trait.internal.UniformsManager());
		updateBoundsFromMesh();
	}

	function updateBoundsFromMesh() {
		if (textMesh == null) return;
		var dimensions = new Float32Array(3);
		dimensions[0] = textMesh.data.geom.aabb.x;
		dimensions[1] = textMesh.data.geom.aabb.y;
		dimensions[2] = textMesh.data.geom.aabb.z;
		if (raw == null) raw = cast { type: "text_object", name: name, dimensions: dimensions };
		else raw.dimensions = dimensions;
		transform.dim.setFrom(textMesh.data.geom.aabb);
		transform.radius = textMesh.transform.radius;
		transform.buildMatrix();
	}

	function appendFill(contours: Array<Array<Vec4>>, cursorX: Float, z: Float, target: Array<Float>, reverse: Bool) {
		var points = fontProcessor.triangulate(contours, reverse);
		var i = 0;
		while (i + 5 < points.length) {
			tri(target, cursorX + points[i], points[i + 1], z, cursorX + points[i + 2], points[i + 3], z, cursorX + points[i + 4], points[i + 5], z);
			i += 6;
		}
	}

	function buildSides(contours: Array<Array<Vec4>>, cursorX: Float, target: Array<Float>) {
		for (contour in contours) for (i in 0...contour.length - 1) {
			var a = contour[i];
			var b = contour[i + 1];
			tri(target, cursorX + a.x, a.y, 0.001, cursorX + b.x, b.y, 0.001, cursorX + b.x, b.y, -extrusionDepth);
			tri(target, cursorX + a.x, a.y, 0.001, cursorX + b.x, b.y, -extrusionDepth, cursorX + a.x, a.y, -extrusionDepth);
		}
	}

	function packMesh(caps: Array<Float>, sides: Array<Float>): {raw: TMeshData, scale: Float, centerX: Float, centerY: Float, centerZ: Float, width: Float, height: Float, depth: Float} {
		var maxdim = Math.max(1.0, extrusionDepth);
		for (value in caps) maxdim = Math.max(maxdim, Math.abs(value));
		for (value in sides) maxdim = Math.max(maxdim, Math.abs(value));
		var minX = 1e30;
		var minY = 1e30;
		var minZ = 1e30;
		var maxX = -1e30;
		var maxY = -1e30;
		var maxZ = -1e30;
		for (triangles in [caps, sides]) for (i in 0...Std.int(triangles.length / 3)) {
			var x = triangles[i * 3];
			var y = triangles[i * 3 + 1];
			var z = triangles[i * 3 + 2];
			minX = Math.min(minX, x);
			minY = Math.min(minY, y);
			minZ = Math.min(minZ, z);
			maxX = Math.max(maxX, x);
			maxY = Math.max(maxY, y);
			maxZ = Math.max(maxZ, z);
		}
		var centerX = (minX + maxX) * 0.5;
		var centerY = (minY + maxY) * 0.5;
		var centerZ = (minZ + maxZ) * 0.5;
		var count = Std.int((caps.length + sides.length) / 3);
		var pos = new Int16Array(count * 4);
		var nor = new Int16Array(count * 2);
		var tex = new Int16Array(count * 2);
		var tang = new Int16Array(count * 4);
		var capIndices = new Uint32Array(Std.int(caps.length / 3));
		var sideIndices = new Uint32Array(Std.int(sides.length / 3));
		var vertex = 0;
		function writeTriangles(triangles: Array<Float>, indices: Uint32Array) {
			var triangle = 0;
			while (triangle < triangles.length) {
				var ax = triangles[triangle];
				var ay = triangles[triangle + 1];
				var az = triangles[triangle + 2];
				var bx = triangles[triangle + 3];
				var by = triangles[triangle + 4];
				var bz = triangles[triangle + 5];
				var cx = triangles[triangle + 6];
				var cy = triangles[triangle + 7];
				var cz = triangles[triangle + 8];
				var ux = bx - ax;
				var uy = by - ay;
				var uz = bz - az;
				var vx = cx - ax;
				var vy = cy - ay;
				var vz = cz - az;
				var nx = uy * vz - uz * vy;
				var ny = uz * vx - ux * vz;
				var nz = ux * vy - uy * vx;
				var normalLength = Math.sqrt(nx * nx + ny * ny + nz * nz);
				if (normalLength > 0) {
					nx /= normalLength;
					ny /= normalLength;
					nz /= normalLength;
				}
				for (corner in 0...3) {
					var k = triangle + corner * 3;
					var x = triangles[k] - centerX;
					var y = triangles[k + 1] - centerY;
					var z = triangles[k + 2] - centerZ;
					var pi = vertex * 4;
					var ni = vertex * 2;
					var ti = vertex * 2;
					var tangi = vertex * 4;
					pos[pi] = Std.int(x / maxdim * 32767);
					pos[pi + 1] = Std.int(y / maxdim * 32767);
					pos[pi + 2] = Std.int(z / maxdim * 32767);
					pos[pi + 3] = Std.int(nz * 32767);
					nor[ni] = Std.int(nx * 32767);
					nor[ni + 1] = Std.int(ny * 32767);
					tex[ti] = Std.int((x / maxdim * 0.5 + 0.5) * 32767);
					tex[ti + 1] = Std.int((y / maxdim * 0.5 + 0.5) * 32767);
					tang[tangi] = 32767;
					tang[tangi + 1] = 0;
					tang[tangi + 2] = 0;
					tang[tangi + 3] = 32767;
					indices[Std.int(triangle / 3) + corner] = vertex;
					vertex++;
				}
				triangle += 9;
			}
		}
		writeTriangles(caps, capIndices);
		writeTriangles(sides, sideIndices);
		var vertexArrays: Array<TVertexArray> = [
			{attrib: "pos", values: pos, data: "short4norm"},
			{attrib: "nor", values: nor, data: "short2norm"},
			{attrib: "tex", values: tex, data: "short2norm"},
			{attrib: "tang", values: tang, data: "short4norm"}
		];
		var indexArrays: Array<TIndexArray> = [];
		if (capIndices.length > 0) indexArrays.push({material: 0, values: capIndices});
		if (sideIndices.length > 0) indexArrays.push({material: 1, values: sideIndices});
		var name = "TextObject_" + (nextMeshId++);
		return {
			raw: {name: name, sorting_index: 0, vertex_arrays: vertexArrays, index_arrays: indexArrays, scale_pos: maxdim},
			scale: maxdim,
			centerX: centerX,
			centerY: centerY,
			centerZ: centerZ,
			width: maxX - minX,
			height: maxY - minY,
			depth: maxZ - minZ
		};
	}

	function drawOutline(draw: RenderDraw) {
		if (outlineStrength <= 0 || fontProcessor == null || Scene.active == null || Scene.active.camera == null) return;
		var metrics = StbTruetype.stbtt_GetFontVMetrics(fontProcessor.info);
		var objectScale = Math.max(transform.world.right().length(), Math.max(transform.world.look().length(), transform.world.up().length()));
		var lineWidth = outlineStrength * 0.2 * (metrics.ascent - metrics.descent) * worldScale * objectScale;
		var cursorX = 0.0;
		var matrix = transform.world;
		for (i in 0...text.length) {
			var code = text.charCodeAt(i);
			if (code == 10) continue;
			var contours = fontProcessor.getGlyphContours(code, curveSteps);
			for (contour in contours) {
				var segmentCount = contour.length - 1;
				var frontPoints: Array<Vec4> = [];
				var backPoints: Array<Vec4> = [];
				for (j in 0...segmentCount) {
					var a = contour[j];
					var b = contour[j + 1];
					var p1 = new Vec4((cursorX + a.x) * worldScale - centerX, a.y * worldScale - centerY, 0.001 - centerZ, 1).applymat4(matrix);
					var p2 = new Vec4((cursorX + b.x) * worldScale - centerX, b.y * worldScale - centerY, 0.001 - centerZ, 1).applymat4(matrix);
					var b1 = new Vec4((cursorX + a.x) * worldScale - centerX, a.y * worldScale - centerY, -extrusionDepth - centerZ, 1).applymat4(matrix);
					var b2 = new Vec4((cursorX + b.x) * worldScale - centerX, b.y * worldScale - centerY, -extrusionDepth - centerZ, 1).applymat4(matrix);
					frontPoints.push(p1);
					backPoints.push(b1);
					draw.linevWorldWidth(p1, p2, outlineColor, lineWidth);
					if (extrusionDepth != 0) draw.linevWorldWidth(b1, b2, outlineColor, lineWidth);
				}
				if (extrusionDepth != 0) for (j in 0...segmentCount) {
					var previous = (j + segmentCount - 1) % segmentCount;
					var before = contour[previous];
					var point = contour[j];
					var after = contour[j + 1];
					var inX = point.x - before.x;
					var inY = point.y - before.y;
					var outX = after.x - point.x;
					var outY = after.y - point.y;
					var inLength = Math.sqrt(inX * inX + inY * inY);
					var outLength = Math.sqrt(outX * outX + outY * outY);
					var turnCos = inLength > 0 && outLength > 0 ? (inX * outX + inY * outY) / (inLength * outLength) : 1.0;
					if (turnCos < 0.6428) draw.linevWorldWidth(frontPoints[j], backPoints[j], outlineColor, lineWidth);
				}
			}
			cursorX += fontProcessor.getAdvanceWidth(code);
		}
	}

	function tri(target: Array<Float>, ax: Float, ay: Float, az: Float, bx: Float, by: Float, bz: Float, cx: Float, cy: Float, cz: Float) {
		target.push(ax * worldScale);
		target.push(ay * worldScale);
		target.push(az);
		target.push(bx * worldScale);
		target.push(by * worldScale);
		target.push(bz);
		target.push(cx * worldScale);
		target.push(cy * worldScale);
		target.push(cz);
	}

	override public function remove() {
		requestId++;
		if (renderCallback != null) {
			RenderDraw.removeOnRender(renderCallback);
			renderCallback = null;
		}
		if (textMesh != null) {
			textMesh.remove();
			textMesh = null;
		}
		super.remove();
	}

	public function textSplit(callback: Array<MeshObject> -> Void): Void {
		var result: Array<MeshObject> = [];

		if (textMesh == null || fontProcessor == null || materials == null || materials.length == 0 || materials[0] == null) {
			callback(result);
			return;
		}

		var fillMat = materials[0];
		var sideMat = materials.length > 1 && materials[1] != null ? materials[1] : fillMat;

		var cursorX = 0.0;

		for (i in 0...text.length) {
			var code = text.charCodeAt(i);

			if (code == 10) continue;

			var contours = fontProcessor.getGlyphContours(code, curveSteps);

			if (contours.length > 0) {
				var caps: Array<Float> = [];
				var sides: Array<Float> = [];

				if (this.fill) {
					appendFill(contours, cursorX, 0.001, caps, false);

					if (extrusionDepth != 0) {
						appendFill(contours, cursorX, -extrusionDepth, caps, true);
					}
				}

				if (extrusionDepth != 0) {
					buildSides(contours, cursorX, sides);
				}

				if (caps.length >= 9 || sides.length >= 9) {
					var packed = packMesh(caps, sides);

					var data = new MeshData(
						packed.raw,
						function(value: MeshData) {}
					);

					data.geom.calculateAABB();
					data.geom.aabb.set(
						packed.width,
						packed.height,
						packed.depth
					);
					data.name = packed.raw.name;
					data.scalePos = packed.scale;

					var materials = new Vector<MaterialData>(
						extrusionDepth == 0 ? 1 : 2
					);

					materials[0] = fillMat;

					if (extrusionDepth != 0) {
						materials[1] = sideMat;
					}

					var letterMesh = new MeshObject(data, materials);
					letterMesh.name = String.fromCharCode(code);

					var dimensions = new Float32Array(3);
					dimensions[0] = packed.width;
					dimensions[1] = packed.height;
					dimensions[2] = packed.depth;

					letterMesh.raw = cast {
						type: "mesh_object",
						name: packed.raw.name,
						data_ref: packed.raw.name,
						dimensions: dimensions
					};

					letterMesh.transform.dim.setFrom(data.geom.aabb);
					letterMesh.transform.radius = 0.5 * Math.sqrt(
						dimensions[0] * dimensions[0] +
						dimensions[1] * dimensions[1] +
						dimensions[2] * dimensions[2]
					);

					letterMesh.setParent(this);
					letterMesh.transform.loc.set(
						packed.centerX - centerX,
						packed.centerY - centerY,
						packed.centerZ - centerZ
					);
					letterMesh.transform.buildMatrix();

					letterMesh.addTrait(
						new armory.trait.internal.UniformsManager()
					);

					result.push(letterMesh);
				}
			}

			cursorX += fontProcessor.getAdvanceWidth(code);
		}

		callback(result);
	}

}
