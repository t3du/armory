package armory.object;

/*
 * VoronoiFractureExtension
 * 3D Voronoi fracture generator for both concave and convex geometries.
 * Uses BooleanCSGExtension to perform CSG intersection operations
 * and loose-part separation, avoiding duplicated CSG logic.
 */

import haxe.ds.Vector;
import iron.Scene;
import iron.data.MaterialData;
import iron.data.MeshData;
import iron.data.SceneFormat.TIndexArray;
import iron.data.SceneFormat.TMeshData;
import iron.data.SceneFormat.TVertexArray;
import iron.math.Vec4;
import iron.object.MeshObject;
import iron.object.Object;
import kha.arrays.Int16Array;
import kha.arrays.Uint32Array;

typedef VoronoiFractureParams = {
	/** Number of Voronoi seed points / fragments to generate (default: 10) **/
	@:optional var numPoints: Int;

	/** Deterministic pseudorandom seed. 0 = random (default: 0) **/
	@:optional var seed: Int;

	/** Distribution: 0 = Uniform, 1 = Impact / Cluster, 2 = Custom points (default: 0) **/
	@:optional var distribution: Int;

	/** Impact point in world coordinates (default: object center) **/
	@:optional var impactPoint: Vec4;

	/** Impact concentration radius when distribution == 1 (default: 1.0) **/
	@:optional var impactRadius: Float;

	/** Array of custom points in world coordinates when distribution == 2 **/
	@:optional var customPoints: Array<Vec4>;

	/** Material for interior cut faces (default: object material) **/
	@:optional var interiorMaterial: MaterialData;

	/** Margin / gap between fragments [0.0 - 0.5] (default: 0.0) **/
	@:optional var margin: Float;

	/** Separate disconnected pieces resulting from cuts on concave meshes (default: false) **/
	@:optional var separateLooseParts: Bool;
}

class VoronoiFractureExtension {

	static inline var EPS = 1e-5;

	/**
	 * Overload that accepts a VoronoiFractureParams struct.
	 */
	static public function fracture(object: Object, ?params: VoronoiFractureParams): Array<Object> {
		if (params == null) params = {};
		return createResult(
			object,
			params.numPoints != null && params.numPoints > 0 ? params.numPoints : 10,
			params.seed != null ? params.seed : 0,
			params.distribution != null ? params.distribution : 0,
			params.impactPoint,
			params.impactRadius != null && params.impactRadius > 0.0 ? params.impactRadius : 1.0,
			params.interiorMaterial,
			params.margin != null ? Math.max(0.0, Math.min(0.5, params.margin)) : 0.0,
			params.separateLooseParts != null ? params.separateLooseParts : false,
			params.customPoints
		);
	}

	/**
	 * Generates a 3D Voronoi fracture on any mesh object (concave or convex).
	 * Uses BooleanCSGExtension.createResult to intersect the object with each convex cell.
	 *
	 * @param object Mesh to fracture.
	 * @param numPoints Desired number of fragments.
	 * @param seed Random seed (0 = random).
	 * @param distribution 0: Uniform, 1: Clustered around impactPoint, 2: Custom points.
	 * @param impactPoint World-space coordinates of the impact center.
	 * @param impactRadius Influence radius of the impact.
	 * @param interiorMaterial Material for interior cut faces.
	 * @param margin Spacing between cells (0.0 to 0.5).
	 * @param separateLooseParts If true, separates disconnected fragments on concave meshes.
	 * @param customPoints Custom seed points.
	 * @return Array of fragment objects created in the scene.
	 */
	static public function createResult(
		object: Object,
		numPoints: Int = 10,
		seed: Int = 0,
		distribution: Int = 0,
		impactPoint: Vec4 = null,
		impactRadius: Float = 1.0,
		interiorMaterial: MaterialData = null,
		margin: Float = 0.0,
		separateLooseParts: Bool = false,
		customPoints: Array<Vec4> = null
	): Array<Object> {
		if (Scene.active == null) throw "Voronoi Fracture requires an active scene.";
		if (object == null || !Std.isOfType(object, MeshObject))
			throw "Voronoi Fracture input must be a valid MeshObject.";

		var mesh: MeshObject = cast object;
		if (mesh.data == null) throw "Voronoi Fracture input is missing mesh data.";
		if (mesh.data.isSkinned || mesh.data.raw.morph_target != null)
			throw "Voronoi Fracture does not support skinned meshes or morph targets.";
		if (mesh.materials == null || mesh.materials.length == 0)
			throw "Voronoi Fracture requires the input object to have at least one material slot.";

		mesh.transform.update();

		// Compute the mesh AABB in world space
		var pos = mesh.data.geom.positions;
		if (pos == null || pos.values == null) throw "Mesh has no position data.";
		var values: Int16Array = pos.values;
		var stride = pos.size == null || pos.size <= 0 ? 4 : pos.size;
		var matrix = mesh.transform.worldUnpack;

		var minX = Math.POSITIVE_INFINITY;
		var minY = Math.POSITIVE_INFINITY;
		var minZ = Math.POSITIVE_INFINITY;
		var maxX = Math.NEGATIVE_INFINITY;
		var maxY = Math.NEGATIVE_INFINITY;
		var maxZ = Math.NEGATIVE_INFINITY;

		var meshVertices = new Array<Vec4>();
		for (i in 0...Std.int(values.length / stride)) {
			var o = i * stride;
			var lx = values[o] / 32767.0;
			var ly = values[o + 1] / 32767.0;
			var lz = values[o + 2] / 32767.0;

			var wx = lx * matrix._00 + ly * matrix._10 + lz * matrix._20 + matrix._30;
			var wy = lx * matrix._01 + ly * matrix._11 + lz * matrix._21 + matrix._31;
			var wz = lx * matrix._02 + ly * matrix._12 + lz * matrix._22 + matrix._32;

			meshVertices.push(new Vec4(wx, wy, wz));

			minX = Math.min(minX, wx);
			minY = Math.min(minY, wy);
			minZ = Math.min(minZ, wz);
			maxX = Math.max(maxX, wx);
			maxY = Math.max(maxY, wy);
			maxZ = Math.max(maxZ, wz);
		}

		var sizeX = Math.max(maxX - minX, 0.1);
		var sizeY = Math.max(maxY - minY, 0.1);
		var sizeZ = Math.max(maxZ - minZ, 0.1);
		var center = new Vec4((minX + maxX) * 0.5, (minY + maxY) * 0.5, (minZ + maxZ) * 0.5);

		// Generate Voronoi seeds
		var seeds = generateSeeds(
			new Vec4(minX, minY, minZ),
			new Vec4(maxX, maxY, maxZ),
			center,
			numPoints,
			seed,
			distribution,
			impactPoint,
			impactRadius,
			customPoints,
			meshVertices
		);

		if (seeds.length < 2) return [mesh];

		// Wide bounding box to ensure cells cover the entire geometry
		var padX = sizeX * 1.5;
		var padY = sizeY * 1.5;
		var padZ = sizeZ * 1.5;
		var boxMin = new Vec4(minX - padX, minY - padY, minZ - padZ);
		var boxMax = new Vec4(maxX + padX, maxY + padY, maxZ + padZ);

		// Cell materials: if an interior material was specified, use it for cut faces
		var cellMaterials = new Vector<MaterialData>(1);
		cellMaterials[0] = interiorMaterial != null ? interiorMaterial : mesh.materials[0];

		var shards = new Array<Object>();
		var shardIndex = 0;

		for (i in 0...seeds.length) {
			var seedPoint = seeds[i];

			// 1. Clip the box by Voronoi bisector planes (3D Sutherland-Hodgman)
			var cellPolygons = clipVoronoiCell(seedPoint, seeds, i, boxMin, boxMax, margin);
			if (cellPolygons == null || cellPolygons.length == 0) continue;

			// 2. Build a temporary mesh object for the convex cell
			var cellMesh = createCellMesh(cellPolygons, cellMaterials, "_VoronoiCellTemp_" + i);
			if (cellMesh == null) continue;

			// 3. CSG intersection using BooleanCSGExtension (operation 2: intersect)
			var shard: Object = null;
			try {
				shard = BooleanCSGExtension.createResult(mesh, cellMesh, 2);
			}
			catch (e: Dynamic) {
				trace("VoronoiFractureExtension: Skipping cell " + i + " (" + e + ")");
			}

			// Immediately remove the temporary cell object
			cellMesh.remove();

			if (shard == null) continue;

			shard.name = mesh.name + "_shard_" + shardIndex;
			shardIndex++;

			// 4. Separate disconnected parts on concave meshes via BooleanCSGExtension
			if (separateLooseParts) {
				var parts: Array<Object> = null;
				try {
					parts = BooleanCSGExtension.separateObject(shard, 0);
				}
				catch (e: Dynamic) {}

				if (parts != null && parts.length > 1) {
					shard.remove();
					for (part in parts) {
						part.name = mesh.name + "_shard_" + shardIndex;
						shardIndex++;
						shards.push(part);
					}
				}
				else {
					// If there is only 1 part, separateObject created a duplicate object (_Part0).
					// Remove that duplicate and keep the original shard.
					if (parts != null && parts.length == 1) {
						parts[0].remove();
					}
					shards.push(shard);
				}
			}
			else {
				shards.push(shard);
			}
		}

		return shards;
	}

	/**
	 * Generates seed points based on the selected distribution.
	 */
	static function generateSeeds(
		min: Vec4,
		max: Vec4,
		center: Vec4,
		count: Int,
		seed: Int,
		distribution: Int,
		impactPoint: Vec4,
		impactRadius: Float,
		customPoints: Array<Vec4>,
		meshVertices: Array<Vec4>
	): Array<Vec4> {
		if ((distribution == 2 || distribution == 3) && customPoints != null && customPoints.length > 0) {
			return customPoints.copy();
		}

		var rngState: Int = seed != 0 ? Math.floor(Math.abs(seed)) : Std.int(Math.random() * 1000000) + 1;
		inline function random(): Float {
			rngState = (rngState * 1664525 + 1013904223) & 0x7fffffff;
			return (rngState / 2147483647.0);
		}

		var seeds = new Array<Vec4>();
		var sizeX = max.x - min.x;
		var sizeY = max.y - min.y;
		var sizeZ = max.z - min.z;

		// Distribution 1: Impact / Cluster
		if (distribution == 1) {
			var impX = impactPoint != null ? impactPoint.x : center.x;
			var impY = impactPoint != null ? impactPoint.y : center.y;
			var impZ = impactPoint != null ? impactPoint.z : center.z;
			var radius = impactRadius > 0 ? impactRadius : Math.max(sizeX, Math.max(sizeY, sizeZ)) * 0.5;

			if (meshVertices != null && meshVertices.length > 0) {
				var sorted = meshVertices.copy();
				sorted.sort(function(a, b) {
					var da = (a.x - impX) * (a.x - impX) + (a.y - impY) * (a.y - impY) + (a.z - impZ) * (a.z - impZ);
					var db = (b.x - impX) * (b.x - impX) + (b.y - impY) * (b.y - impY) + (b.z - impZ) * (b.z - impZ);
					return da < db ? -1 : (da > db ? 1 : 0);
				});

				var pool = Std.int(Math.min(sorted.length, Math.max(count * 3, 20)));
				for (i in 0...count) {
					var idx = Math.floor(Math.pow(random(), 1.6) * pool);
					if (idx >= sorted.length) idx = sorted.length - 1;
					var v = sorted[idx];
					seeds.push(new Vec4(v.x, v.y, v.z));
				}
				return seeds;
			}
			else {
				for (i in 0...count) {
					var r = Math.pow(random(), 1.8) * radius;
					var theta = random() * 2.0 * Math.PI;
					var phi = Math.acos(2.0 * random() - 1.0);
					var px = impX + r * Math.sin(phi) * Math.cos(theta);
					var py = impY + r * Math.sin(phi) * Math.sin(theta);
					var pz = impZ + r * Math.cos(phi);
					seeds.push(new Vec4(px, py, pz));
				}
				return seeds;
			}
		}

		// Distribution 2: Uniform bounding box (classic AABB)
		if (distribution == 2) {
			for (i in 0...count) {
				seeds.push(new Vec4(
					min.x + random() * sizeX,
					min.y + random() * sizeY,
					min.z + random() * sizeZ
				));
			}
			return seeds;
		}

		// Distribution 0 (default): Mesh surface sampling (Mitchell Best-Candidate)
		// For concave geometries (torus, cups, Suzanne, etc.), this prevents seeds
		// from falling inside central holes or empty spaces, distributing them
		// more evenly across the object's surface.
		if (meshVertices != null && meshVertices.length > 0) {
			var numCandidates = 10;
			for (i in 0...count) {
				if (seeds.length == 0) {
					var idx = Math.floor(random() * meshVertices.length);
					var v = meshVertices[idx];
					seeds.push(new Vec4(v.x, v.y, v.z));
				}
				else {
					var best: Vec4 = null;
					var maxMinDist = -1.0;

					for (c in 0...numCandidates) {
						var idx = Math.floor(random() * meshVertices.length);
						var cand = meshVertices[idx];

						var minDist = Math.POSITIVE_INFINITY;
						for (s in seeds) {
							var dx = cand.x - s.x;
							var dy = cand.y - s.y;
							var dz = cand.z - s.z;
							var d = dx * dx + dy * dy + dz * dz;
							if (d < minDist) minDist = d;
						}

						if (minDist > maxMinDist) {
							maxMinDist = minDist;
							best = cand;
						}
					}

					if (best != null) {
						seeds.push(new Vec4(best.x, best.y, best.z));
					}
					else {
						var idx = Math.floor(random() * meshVertices.length);
						var v = meshVertices[idx];
						seeds.push(new Vec4(v.x, v.y, v.z));
					}
				}
			}
			return seeds;
		}

		// Uniform fallback when no vertices are available
		for (i in 0...count) {
			seeds.push(new Vec4(
				min.x + random() * sizeX,
				min.y + random() * sizeY,
				min.z + random() * sizeZ
			));
		}
		return seeds;
	}

	/**
	 * Builds a convex Voronoi polyhedral cell by clipping it against bisector planes.
	 */
	static function clipVoronoiCell(
		site: Vec4,
		allSites: Array<Vec4>,
		siteIndex: Int,
		boxMin: Vec4,
		boxMax: Vec4,
		margin: Float
	): Array<Array<Vec4>> {
		// 6 faces of the bounding box
		var faces: Array<Array<Vec4>> = [
			// +X
			[new Vec4(boxMax.x, boxMin.y, boxMin.z), new Vec4(boxMax.x, boxMax.y, boxMin.z), new Vec4(boxMax.x, boxMax.y, boxMax.z), new Vec4(boxMax.x, boxMin.y, boxMax.z)],
			// -X
			[new Vec4(boxMin.x, boxMin.y, boxMin.z), new Vec4(boxMin.x, boxMin.y, boxMax.z), new Vec4(boxMin.x, boxMax.y, boxMax.z), new Vec4(boxMin.x, boxMax.y, boxMin.z)],
			// +Y
			[new Vec4(boxMin.x, boxMax.y, boxMin.z), new Vec4(boxMin.x, boxMax.y, boxMax.z), new Vec4(boxMax.x, boxMax.y, boxMax.z), new Vec4(boxMax.x, boxMax.y, boxMin.z)],
			// -Y
			[new Vec4(boxMin.x, boxMin.y, boxMin.z), new Vec4(boxMax.x, boxMin.y, boxMin.z), new Vec4(boxMax.x, boxMin.y, boxMax.z), new Vec4(boxMin.x, boxMin.y, boxMax.z)],
			// +Z
			[new Vec4(boxMin.x, boxMin.y, boxMax.z), new Vec4(boxMax.x, boxMin.y, boxMax.z), new Vec4(boxMax.x, boxMax.y, boxMax.z), new Vec4(boxMin.x, boxMax.y, boxMax.z)],
			// -Z
			[new Vec4(boxMin.x, boxMin.y, boxMin.z), new Vec4(boxMin.x, boxMax.y, boxMin.z), new Vec4(boxMax.x, boxMax.y, boxMin.z), new Vec4(boxMax.x, boxMin.y, boxMin.z)]
		];

		for (j in 0...allSites.length) {
			if (j == siteIndex) continue;
			var other = allSites[j];

			var nx = other.x - site.x;
			var ny = other.y - site.y;
			var nz = other.z - site.z;
			var dist = Math.sqrt(nx * nx + ny * ny + nz * nz);
			if (dist < 1e-6) continue;

			// Normal pointing toward the other site (outward from the current cell)
			var invDist = 1.0 / dist;
			nx *= invDist;
			ny *= invDist;
			nz *= invDist;

			var midX = (site.x + other.x) * 0.5;
			var midY = (site.y + other.y) * 0.5;
			var midZ = (site.z + other.z) * 0.5;
			var w = nx * midX + ny * midY + nz * midZ;

			var newFaces = new Array<Array<Vec4>>();
			var cutPoints = new Array<Vec4>();

			for (face in faces) {
				var clipped = new Array<Vec4>();
				var len = face.length;
				for (k in 0...len) {
					var v1 = face[k];
					var v2 = face[(k + 1) % len];

					var d1 = (nx * v1.x + ny * v1.y + nz * v1.z) - w;
					var d2 = (nx * v2.x + ny * v2.y + nz * v2.z) - w;

					var in1 = d1 <= EPS;
					var in2 = d2 <= EPS;

					if (in1) clipped.push(v1);

					if (in1 != in2) {
						var denom = d2 - d1;
						var t = Math.abs(denom) > 1e-12 ? (-d1) / denom : 0.5;
						if (t < 0.0) t = 0.0;
						else if (t > 1.0) t = 1.0;

						var ix = v1.x + (v2.x - v1.x) * t;
						var iy = v1.y + (v2.y - v1.y) * t;
						var iz = v1.z + (v2.z - v1.z) * t;
						var inter = new Vec4(ix, iy, iz);
						clipped.push(inter);
						cutPoints.push(inter);
					}
				}
				if (clipped.length >= 3) newFaces.push(clipped);
			}

			// Build a planar cap for the current cut
			if (cutPoints.length >= 3) {
				var uniqueCut = new Array<Vec4>();
				for (pt in cutPoints) {
					var duplicate = false;
					for (u in uniqueCut) {
						var dx = pt.x - u.x;
						var dy = pt.y - u.y;
						var dz = pt.z - u.z;
						if (dx * dx + dy * dy + dz * dz < 1e-8) {
							duplicate = true;
							break;
						}
					}
					if (!duplicate) uniqueCut.push(pt);
				}

				if (uniqueCut.length >= 3) {
					var cx = 0.0;
					var cy = 0.0;
					var cz = 0.0;
					for (u in uniqueCut) {
						cx += u.x;
						cy += u.y;
						cz += u.z;
					}
					var invLen = 1.0 / uniqueCut.length;
					cx *= invLen;
					cy *= invLen;
					cz *= invLen;

					// Construct an orthonormal basis on the cutting plane
					var up = Math.abs(nz) < 0.9 ? new Vec4(0, 0, 1) : new Vec4(0, 1, 0);
					var ux = up.y * nz - up.z * ny;
					var uy = up.z * nx - up.x * nz;
					var uz = up.x * ny - up.y * nx;
					var uLen = Math.sqrt(ux * ux + uy * uy + uz * uz);
					if (uLen > 1e-8) {
						ux /= uLen;
						uy /= uLen;
						uz /= uLen;
					}

					var vx = ny * uz - nz * uy;
					var vy = nz * ux - nx * uz;
					var vz = nx * uy - ny * ux;

					// Sort vertices counterclockwise around the cutting plane normal
					uniqueCut.sort(function(a: Vec4, b: Vec4): Int {
						var raX = a.x - cx;
						var raY = a.y - cy;
						var raZ = a.z - cz;
						var rbX = b.x - cx;
						var rbY = b.y - cy;
						var rbZ = b.z - cz;

						var angleA = Math.atan2(raX * vx + raY * vy + raZ * vz, raX * ux + raY * uy + raZ * uz);
						var angleB = Math.atan2(rbX * vx + rbY * vy + rbZ * vz, rbX * ux + rbY * uy + rbZ * uz);
						return angleA < angleB ? -1 : (angleA > angleB ? 1 : 0);
					});

					newFaces.push(uniqueCut);
				}
			}

			faces = newFaces;
			if (faces.length == 0) return null;
		}

		if (margin > 0.0) {
			var scale = 1.0 - margin;
			for (face in faces) {
				for (i in 0...face.length) {
					var v = face[i];
					face[i] = new Vec4(
						site.x + (v.x - site.x) * scale,
						site.y + (v.y - site.y) * scale,
						site.z + (v.z - site.z) * scale
					);
				}
			}
		}

		return faces;
	}

	/**
	 * Creates a temporary MeshObject from the Voronoi polyhedron
	 * so it can be passed to BooleanCSGExtension.
	 */
	static function createCellMesh(polygons: Array<Array<Vec4>>, materials: Vector<MaterialData>, name: String): MeshObject {
		var minX = Math.POSITIVE_INFINITY;
		var minY = Math.POSITIVE_INFINITY;
		var minZ = Math.POSITIVE_INFINITY;
		var maxX = Math.NEGATIVE_INFINITY;
		var maxY = Math.NEGATIVE_INFINITY;
		var maxZ = Math.NEGATIVE_INFINITY;

		for (poly in polygons) {
			for (v in poly) {
				minX = Math.min(minX, v.x);
				minY = Math.min(minY, v.y);
				minZ = Math.min(minZ, v.z);
				maxX = Math.max(maxX, v.x);
				maxY = Math.max(maxY, v.y);
				maxZ = Math.max(maxZ, v.z);
			}
		}

		if (minX == Math.POSITIVE_INFINITY) return null;

		var center = new Vec4((minX + maxX) * 0.5, (minY + maxY) * 0.5, (minZ + maxZ) * 0.5);
		var scale = Math.max(maxX - minX, Math.max(maxY - minY, maxZ - minZ)) * 0.5;
		if (scale < 1e-6) scale = 1.0;

		inline function toShort(v: Float): Int {
			return Std.int(Math.round(Math.max(-1.0, Math.min(1.0, v)) * 32767.0));
		}

		var packedPositions = new Array<Int>();
		var packedNormals = new Array<Int>();
		var packedTangents = new Array<Int>();
		var packedTexcoords = new Array<Int>();
		var indices = new Array<Int>();

		for (poly in polygons) {
			if (poly.length < 3) continue;

			// Quantize and merge duplicate vertices within the polygon
			var qVerts = new Array<{sx: Int, sy: Int, sz: Int}>();
			for (v in poly) {
				var sx = toShort((v.x - center.x) / scale);
				var sy = toShort((v.y - center.y) / scale);
				var sz = toShort((v.z - center.z) / scale);

				if (qVerts.length > 0) {
					var last = qVerts[qVerts.length - 1];
					if (last.sx == sx && last.sy == sy && last.sz == sz) continue;
				}
				qVerts.push({sx: sx, sy: sy, sz: sz});
			}
			if (qVerts.length > 1) {
				var first = qVerts[0];
				var last = qVerts[qVerts.length - 1];
				if (first.sx == last.sx && first.sy == last.sy && first.sz == last.sz) {
					qVerts.pop();
				}
			}
			if (qVerts.length < 3) continue;

			var v0 = qVerts[0];
			for (k in 1...(qVerts.length - 1)) {
				var v1 = qVerts[k];
				var v2 = qVerts[k + 1];

				// Cross product in quantized short space
				var e1x = v1.sx - v0.sx;
				var e1y = v1.sy - v0.sy;
				var e1z = v1.sz - v0.sz;
				var e2x = v2.sx - v0.sx;
				var e2y = v2.sy - v0.sy;
				var e2z = v2.sz - v0.sz;

				var nx = e1y * e2z - e1z * e2y;
				var ny = e1z * e2x - e1x * e2z;
				var nz = e1x * e2y - e1y * e2x;

				// If the cross product is zero in quantized space, the triangle is degenerate in short4norm
				if (nx == 0 && ny == 0 && nz == 0) continue;

				var len = Math.sqrt(nx * nx + ny * ny + nz * nz);
				var fnx = nx / len;
				var fny = ny / len;
				var fnz = nz / len;

				var tx = Math.abs(fnx) < 0.9 ? 0.0 : 0.0;
				var ty = Math.abs(fnx) < 0.9 ? fnz : 0.0;
				var tz = Math.abs(fnx) < 0.9 ? -fny : 1.0;
				var tlen = Math.sqrt(tx * tx + ty * ty + tz * tz);
				if (tlen > 1e-6) {
					tx /= tlen;
					ty /= tlen;
					tz /= tlen;
				}

				var snx = toShort(fnx);
				var sny = toShort(fny);
				var snz = toShort(fnz);
				var stx = toShort(tx);
				var sty = toShort(ty);
				var stz = toShort(tz);

				for (vert in [v0, v1, v2]) {
					indices.push(indices.length);

					packedPositions.push(vert.sx);
					packedPositions.push(vert.sy);
					packedPositions.push(vert.sz);
					packedPositions.push(32767);

					packedNormals.push(snx);
					packedNormals.push(sny);
					packedNormals.push(snz);
					packedNormals.push(0);

					packedTangents.push(stx);
					packedTangents.push(sty);
					packedTangents.push(stz);
					packedTangents.push(32767);

					packedTexcoords.push(vert.sx);
					packedTexcoords.push(vert.sy);
				}
			}
		}

		if (indices.length == 0) return null;

		var count = Std.int(packedPositions.length / 4);
		var packedPos = new Int16Array(packedPositions.length);
		var packedNor = new Int16Array(packedNormals.length);
		var packedTan = new Int16Array(packedTangents.length);
		var packedTex = new Int16Array(packedTexcoords.length);
		for (i in 0...packedPositions.length) packedPos[i] = packedPositions[i];
		for (i in 0...packedNormals.length) packedNor[i] = packedNormals[i];
		for (i in 0...packedTangents.length) packedTan[i] = packedTangents[i];
		for (i in 0...packedTexcoords.length) packedTex[i] = packedTexcoords[i];

		var packedIndices = new Uint32Array(indices.length);
		for (i in 0...indices.length) packedIndices[i] = indices[i];

		var vertexArrays: Array<TVertexArray> = [
			{ attrib: "pos", values: packedPos, data: "short4norm" },
			{ attrib: "nor", values: packedNor, data: "short4norm" },
			{ attrib: "tex", values: packedTex, data: "short2norm" },
			{ attrib: "tang", values: packedTan, data: "short4norm" }
		];

		var indexArrays: Array<TIndexArray> = [
			{ values: packedIndices, material: 0 }
		];

		var raw: TMeshData = {
			name: name,
			sorting_index: 0,
			vertex_arrays: vertexArrays,
			index_arrays: indexArrays,
			scale_pos: scale,
			scale_tex: 1.0
		};

		var data = new MeshData(raw, function(_: MeshData) {});
		data.geom.calculateAABB();

		var cellMesh = Scene.active.addMeshObject(data, materials, Scene.active.root);
		cellMesh.name = name;
		cellMesh.transform.loc.set(center.x, center.y, center.z);
		cellMesh.transform.buildMatrix();
		return cellMesh;
	}
}
