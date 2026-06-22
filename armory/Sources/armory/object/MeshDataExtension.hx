package armory.object;

import iron.math.Vec4;
import iron.data.MeshData;
import iron.data.SceneFormat;

class MeshDataExtension {

	static var meshIndex = 0;
	static public function makeMeshData(points: Array<Vec4>, scaleUV: Float = 0.3, flatShading: Bool = true): MeshData {
		// Need at least 4 points for a 3D hull
		if (points.length < 4) return null;

		while (points.length > 50) points.pop();
		var cm = new ConvexHull(points);

		// Validate hull has enough geometry for a mesh
		if (cm.vertices.length < 4 || cm.face3s.length < 4) return null;

		var maxdim = 1.0;
		var pa = new Array<Float>();
		var na = new Array<Float>();
		for (p in cm.vertices) {
			pa.push(p.x);
			pa.push(p.y);
			pa.push(p.z);
			na.push(0.0);
			na.push(0.0);
			na.push(0.0);

			var ax = Math.abs(p.x);
			var ay = Math.abs(p.y);
			var az = Math.abs(p.z);
			if (ax > maxdim) maxdim = ax;
			if (ay > maxdim) maxdim = ay;
			if (az > maxdim) maxdim = az;
		}
		maxdim *= 2;

		var ind = new Array<Int>();

		if (flatShading) {
			function addFlatNormal(normal: Vec4, fi: Int) {
				if (na[fi * 3] != 0.0 || na[fi * 3 + 1] != 0.0 || na[fi * 3 + 2] != 0.0) {
					pa.push(pa[fi * 3    ]);
					pa.push(pa[fi * 3 + 1]);
					pa.push(pa[fi * 3 + 2]);
					na.push(normal.x);
					na.push(normal.y);
					na.push(normal.z);
					ind.push(Std.int(pa.length / 3 - 1));
				}
				else {
					na[fi * 3    ] = normal.x;
					na[fi * 3 + 1] = normal.y;
					na[fi * 3 + 2] = normal.z;
					ind.push(fi);
				}
			}
			for (f in cm.face3s) {
				// Duplicate vertex for flat normals
				addFlatNormal(f.normal, f.a);
				addFlatNormal(f.normal, f.b);
				addFlatNormal(f.normal, f.c);
			}
		}else {
			var vNormals = [for (i in 0...cm.vertices.length) new Vec4(0, 0, 0)];
			for (f in cm.face3s) {
				vNormals[f.a].add(f.normal);
				vNormals[f.b].add(f.normal);
				vNormals[f.c].add(f.normal);
			}
			for (vn in vNormals) vn.normalize();
			na = [];
			for (vn in vNormals) {
				na.push(vn.x);
				na.push(vn.y);
				na.push(vn.z);
			}
			for (f in cm.face3s) {
				ind.push(f.a);
				ind.push(f.b);
				ind.push(f.c);
			}
		}

		// TODO:
		var n = Std.int(pa.length / 3);
		var paa = new kha.arrays.Int16Array(n * 4);
		var naa = new kha.arrays.Int16Array(n * 2);
		var texa = new kha.arrays.Int16Array(n * 2);
		var invdim = 1 / maxdim;

		var tanga = new kha.arrays.Int16Array(n * 4);
		
		for (i in 0...n) {
			var px = pa[i * 3];
			var py = pa[i * 3 + 1];
			var pz = pa[i * 3 + 2];
			var nx = Math.abs(na[i * 3]);
			var ny = Math.abs(na[i * 3 + 1]);
			var nz = Math.abs(na[i * 3 + 2]);

			paa.set(i * 4,     Std.int(px * 32767 * invdim));
			paa.set(i * 4 + 1, Std.int(py * 32767 * invdim));
			paa.set(i * 4 + 2, Std.int(pz * 32767 * invdim));
			naa.set(i * 2    , Std.int(na[i * 3    ] * 32767 * invdim));
			naa.set(i * 2 + 1, Std.int(na[i * 3 + 1] * 32767 * invdim));
			paa.set(i * 4 + 3, Std.int(na[i * 3 + 2] * 32767 * invdim));

			var u: Float = 0;
			var v: Float = 0;

			if (nx > ny && nx > nz) {
		        u = pz * invdim * scaleUV + 0.5;
		        v = py * invdim * scaleUV + 0.5;
		    } else if (ny > nx && ny > nz) {
		        u = px * invdim * scaleUV + 0.5;
		        v = pz * invdim * scaleUV + 0.5;
		    } else {
		        u = px * invdim * scaleUV + 0.5;
		        v = py * invdim * scaleUV + 0.5;
		    }

			texa.set(i * 2,     Std.int(u * 32767));
			texa.set(i * 2 + 1, Std.int(v * 32767));

			var tan = new Vec4();
			if (nx > ny && nx > nz)
			    tan.set(0, 0, 1); 
			else if (ny > nx && ny > nz)
			    tan.set(1, 0, 0);
			else
			    tan.set(1, 0, 0);
			tan.normalize();

			tanga.set(i * 4,     Std.int(tan.x * 32767));
			tanga.set(i * 4 + 1, Std.int(tan.y * 32767));
			tanga.set(i * 4 + 2, Std.int(tan.z * 32767));
			tanga.set(i * 4 + 3, 32767);

		}

		var inda = new kha.arrays.Uint32Array(ind.length);
		for (i in 0...ind.length) inda.set(i, ind[i]);

		var pos: TVertexArray = { attrib: "pos", values: paa, data: "short4norm" };
		var nor: TVertexArray = { attrib: "nor", values: naa, data: "short2norm" };
		var tex: TVertexArray = { attrib: "tex", values: texa, data: "short2norm" };
		var tang: TVertexArray = { attrib: "tang", values: tanga, data: "short4norm" };

		var indices: TIndexArray = { material: 0, values: inda };

		var rawmesh: TMeshData = {
			name: "TempMesh" + (meshIndex++),
			sorting_index: 0,
			vertex_arrays: [pos, nor, tex, tang],
			index_arrays: [indices],
			scale_pos: maxdim
		};

		// Synchronous on Krom
		var md = new MeshData(rawmesh, function(d: MeshData) {});
		md.geom.calculateAABB();
		return md;
	}
}

// Based on work by qiao https://github.com/qiao
// This is a convex hull generator using the incremental method
// The complexity is O(n^2) where n is the number of vertices
class ConvexHull {

	var faces = [[0, 1, 2], [0, 2, 1]];
	public var face3s = new Array<Face3>();
	public var vertices = new Array<Vec4>();

	public function new(vertices: Array<Vec4>) {

		for (i in 3...vertices.length) addPoint(i, vertices);

		// Push vertices into array, skipping those inside the hull
		// Map from old vertex id to new id
		var id = 0;
		var newId = new Array<Int>();
		for (i in 0...vertices.length) newId.push(-1);

		for (i in 0...faces.length) {
			 var face = faces[i];
			 for (j in 0...3) {
				if (newId[face[j]] == -1) {
					newId[face[j]] = id++;
					this.vertices.push(vertices[face[j]]);
				}
				face[j] = newId[face[j]];
			 }
		}

		for (i in 0...faces.length) {
			face3s.push(new Face3(faces[i][0], faces[i][1], faces[i][2]));
		}

		computeFaceNormals();
	}

	var cb = new Vec4();
	var ab = new Vec4();
	function computeFaceNormals() {
		for (f in 0...face3s.length) {
			var face = face3s[f];
			var va = vertices[face.a];
			var vb = vertices[face.b];
			var vc = vertices[face.c];
			cb.subvecs(vc, vb);
			ab.subvecs(va, vb);
			cb.cross(ab);
			cb.normalize();
			face.normal.setFrom(cb);
		}
	}

	function addPoint(vertexId: Int, vertices: Array<Vec4>) {
		var vertex = vertices[vertexId].clone();

		var mag = vertex.length();
		vertex.x += mag * randomOffset();
		vertex.y += mag * randomOffset();
		vertex.z += mag * randomOffset();

		var hole: Array<Array<Int>> = [];
		var f = 0;
		while (f < faces.length) {
			var face = faces[f];

			// For each face, if the vertex can see it,
			// then we try to add the face's edges into the hole
			if (visible(face, vertex, vertices)) {
				for (e in 0...3) {
					var edge = [face[e], face[(e + 1) % 3]];
					var boundary = true;

					// Remove duplicated edges
					for (h in 0...hole.length) {
						if (equalEdge(hole[h], edge)) {
							hole[h] = hole[hole.length - 1];
							hole.pop();
							boundary = false;
							break;
						}
					}
					if (boundary) hole.push(edge);
				}

				faces[f] = faces[faces.length - 1];
				faces.pop();
			}
			else {
				f++;
			}
		}

		// Construct the new faces formed by the edges of the hole and the vertex
		for (h in 0...hole.length) {
			faces.push([hole[h][0], hole[h][1], vertexId]);
		}
	}

	// Whether the face is visible from the vertex
	function visible(face: Array<Int>, vertex: Vec4, vertices: Array<Vec4>): Bool {
		var va = vertices[face[0]];
		var vb = vertices[face[1]];
		var vc = vertices[face[2]];
		var n = normal(va, vb, vc);
		var dist = n.dot(va); // Distance from face to origin
		return n.dot(vertex) >= dist;
	}

	function normal(va: Vec4, vb: Vec4, vc: Vec4): Vec4 {
		var cb = new Vec4();
		var ab = new Vec4();
		cb.subvecs(vc, vb);
		ab.subvecs(va, vb);
		cb.cross(ab);
		cb.normalize();
		return cb;
	}

	function equalEdge(ea: Array<Int>, eb: Array<Int>): Bool {
		return ea[0] == eb[1] && ea[1] == eb[0];
	}

	function randomOffset(): Float {
		return (Math.random() - 0.5) * 2 * 1e-6;
	}
}

class Face3 {

	public var a: Int;
	public var b: Int;
	public var c: Int;
	public var normal: Vec4;

	public function new(a: Int, b: Int, c: Int) {
		this.a = a;
		this.b = b;
		this.c = c;
		normal = new Vec4();
	}
}