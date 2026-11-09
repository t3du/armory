package armory.object;

/*
 https://github.com/evanw/csg.js/
 * Based on csg.js by Evan Wallace, Copyright (c) 2011 Evan Wallace.
 * Distributed under the MIT License:
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files, to deal in the Software
 * without restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies, and to
 * permit persons to whom the Software is furnished to do so, subject to the
 * following conditions: The above copyright notice and this permission notice
 * shall be included in all copies or substantial portions of the Software.
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import haxe.ds.Vector;
import iron.Scene;
import iron.data.MeshData;
import iron.data.MaterialData;
import iron.math.Mat4;
import iron.math.Quat;
import iron.math.Vec4;
import iron.data.SceneFormat.TIndexArray;
import iron.data.SceneFormat.TMeshData;
import iron.data.SceneFormat.TVertexArray;
import iron.object.MeshObject;
import iron.object.Object;
import kha.arrays.Int16Array;
import kha.arrays.Uint32Array;

class BooleanCSGExtension {

	static public function createResult(objectA: Object, objectB: Object, operation: Int): Object {
		if (Scene.active == null) throw "Boolean CSG requires an active scene.";
		if (objectA == null || objectB == null) throw "Boolean CSG requires two mesh objects.";
		if (!Std.isOfType(objectA, MeshObject) || !Std.isOfType(objectB, MeshObject))
			throw "Boolean CSG inputs must be objects with mesh geometry.";
		var a: MeshObject = cast objectA;
		var b: MeshObject = cast objectB;
		if (a == b) throw "Boolean CSG inputs must be different objects.";
		if (a.data == null || b.data == null) throw "Boolean CSG input is missing mesh data.";
		if (a.data.isSkinned || b.data.isSkinned || a.data.raw.morph_target != null || b.data.raw.morph_target != null)
			throw "Boolean CSG does not support skinned meshes or morph targets.";
		if (a.materials == null || a.materials.length == 0 || b.materials == null || b.materials.length == 0)
			throw "Boolean CSG requires both input objects to have at least one material slot.";

		var polygonsA = meshToPolygons(a, 0);
		var polygonsB = meshToPolygons(b, a.materials.length);
		if (polygonsA.length == 0 || polygonsB.length == 0) throw "Boolean CSG input contains no valid triangles.";

		var solidA = new CSGNode(polygonsA);
		var solidB = new CSGNode(polygonsB);
		var result: Array<CSGPolygon>;
		switch (operation) {
			//union
			case 0:
				solidA.clipTo(solidB);
				solidB.clipTo(solidA);
				solidB.invert();
				solidB.clipTo(solidA);
				solidB.invert();
				solidA.build(solidB.allPolygons());
				result = solidA.allPolygons();
			//subtract
			case 1:
				solidA.invert();
				solidA.clipTo(solidB);
				solidB.clipTo(solidA);
				solidB.invert();
				solidB.clipTo(solidA);
				solidB.invert();
				solidA.build(solidB.allPolygons());
				solidA.invert();
				result = solidA.allPolygons();
			//intersect
			case 2:
				solidA.invert();
				solidB.clipTo(solidA);
				solidB.invert();
				solidA.clipTo(solidB);
				solidB.clipTo(solidA);
				solidA.build(solidB.allPolygons());
				solidA.invert();
				result = solidA.allPolygons();
			default:
				throw 'Unknown Boolean CSG operation "$operation".';
		}

		if (result.length == 0) return null;
		var materials = new Vector<MaterialData>(a.materials.length + b.materials.length);
		for (i in 0...a.materials.length) materials[i] = a.materials[i];
		for (i in 0...b.materials.length) materials[a.materials.length + i] = b.materials[i];
		return polygonsToObject(result, materials, "BooleanCSG_Result", a);
	}

	static public function separateObject(object: Object, mode: Int): Array<Object> {
		if (Scene.active == null) throw "Separate Object requires an active scene.";
		if (object == null) throw "Separate Object requires an object with mesh data.";
		if (!Std.isOfType(object, MeshObject)) throw "Separate Object input must be an object with mesh geometry.";
		var mesh: MeshObject = cast object;
		if (mesh.data == null) throw "Separate Object requires an object with mesh data.";
		if (mesh.materials == null || mesh.materials.length == 0)
			throw "Separate Object requires at least one material slot.";
		if (mesh.data.isSkinned || mesh.data.raw.morph_target != null)
			throw "Separate Object does not support skinned meshes or morph targets.";
		mesh.transform.update();

		var positions = mesh.data.geom.positions;
		if (positions == null || positions.values == null) throw "Mesh has no position data.";
		var positionValues: Int16Array = positions.values;
		var stride = positions.size == null || positions.size <= 0 ? 4 : positions.size;
		var faces = new Array<CSGIndexedTriangle>();
		for (groupIndex in 0...mesh.data.geom.indices.length) {
			var sourceIndices = mesh.data.geom.indices[groupIndex];
			var sourceVertexMap: kha.arrays.Uint32Array = groupIndex < mesh.data.raw.index_arrays.length
				? mesh.data.raw.index_arrays[groupIndex].vertex_map
				: null;
			if (sourceVertexMap != null && sourceVertexMap.length != sourceIndices.length)
				throw 'Mesh "${mesh.name}" has a vertex map whose size does not match its index array.';
			var material = groupIndex < mesh.data.geom.materialIndices.length
				? mesh.data.geom.materialIndices[groupIndex]
				: groupIndex;
			for (i in 0...Std.int(sourceIndices.length / 3)) {
				var offset = i * 3;
				faces.push(new CSGIndexedTriangle(
					sourceIndices[offset], sourceIndices[offset + 1], sourceIndices[offset + 2], material,
					sourceVertexMap == null ? -1 : sourceVertexMap[offset],
					sourceVertexMap == null ? -1 : sourceVertexMap[offset + 1],
					sourceVertexMap == null ? -1 : sourceVertexMap[offset + 2]
				));
			}
		}
		if (faces.length == 0) return [];

		var groups = new Array<SeparateObjectGroup>();
		switch (mode) {
			//looseParts
			case 0:
				groups = looseParts(faces, positionValues, stride);
			//vertexGroups
			case 1:
				groups = vertexGroupParts(mesh, faces, positionValues, stride);
			//material
			case 2:
				if (mesh.materials == null) throw "Separate Object requires material slots for material mode.";
				for (material in 0...mesh.materials.length) {
					var group = new SeparateObjectGroup("Material" + material);
					for (face in faces) if (face.material == material) group.faces.push(face);
					if (group.faces.length > 0) groups.push(group);
				}
			default:
				throw 'Unknown Separate Object mode "$mode".';
		}

		var result = new Array<Object>();
		for (group in groups) {
			var part = createSeparatedObject(mesh, group);
			if (part != null) result.push(part);
		}
		return result;
	}

	static function looseParts(faces: Array<CSGIndexedTriangle>, positions: Int16Array, stride: Int): Array<SeparateObjectGroup> {
		var parents = new Array<Int>();
		for (i in 0...faces.length) parents.push(i);
		var vertexOwners = new Map<String, Int>();
		for (i in 0...faces.length) {
			var face = faces[i];
			for (key in [
				topologyKey(face.a, face.topologyA, positions, stride),
				topologyKey(face.b, face.topologyB, positions, stride),
				topologyKey(face.c, face.topologyC, positions, stride)
			]) {
				var owner = vertexOwners.get(key);
				if (owner == null) vertexOwners.set(key, i);
				else joinRoots(parents, i, owner);
			}
		}
		var groups = new Array<SeparateObjectGroup>();
		var rootIndices = new Map<Int, Int>();
		for (i in 0...faces.length) {
			var root = findRoot(parents, i);
			var groupIndex = rootIndices.get(root);
			if (groupIndex == null) {
				groupIndex = groups.length;
				rootIndices.set(root, groupIndex);
				groups.push(new SeparateObjectGroup("Part" + groupIndex));
			}
			groups[groupIndex].faces.push(faces[i]);
		}
		return groups;
	}

	static function vertexGroupParts(
		mesh: MeshObject,
		faces: Array<CSGIndexedTriangle>,
		positions: Int16Array,
		stride: Int
	): Array<SeparateObjectGroup> {
		var rawGroups = mesh.raw == null ? null : mesh.raw.vertex_groups;
		var meshGroups = mesh.data.raw.vertex_groups;
		var groups = new Array<SeparateObjectGroup>();
		var vertexOwners = new Map<String, Array<Int>>();
		var topologyOwners = new Map<Int, Array<Int>>();
		if (meshGroups != null) {
			for (groupIndex in 0...meshGroups.length) {
				var group = new SeparateObjectGroup(meshGroups[groupIndex].name);
				groups.push(group);
				var indices = meshGroups[groupIndex].indices;
				if (indices == null) continue;
				for (vertexIndex in indices) {
					var owners = topologyOwners.get(vertexIndex);
					if (owners == null) {
						owners = [];
						topologyOwners.set(vertexIndex, owners);
					}
					if (owners.indexOf(groupIndex) < 0) owners.push(groupIndex);
				}
			}
		}
		else if (rawGroups != null) {
			var scale = mesh.data.scalePos;
			if (scale == 0) throw 'Mesh "${mesh.name}" has an invalid position scale.';
			for (groupIndex in 0...rawGroups.length) {
				var rawGroup = rawGroups[groupIndex];
				groups.push(new SeparateObjectGroup(rawGroup.name));
				var values: kha.arrays.Float32Array = rawGroup.value;
				if (values == null) continue;
				for (i in 0...Std.int(values.length / 3)) {
					var key = Std.int(Math.round(values[i * 3] / scale * 32767.0)) + ","
						+ Std.int(Math.round(values[i * 3 + 1] / scale * 32767.0)) + ","
						+ Std.int(Math.round(values[i * 3 + 2] / scale * 32767.0));
					var owners = vertexOwners.get(key);
					if (owners == null) {
						owners = [];
						vertexOwners.set(key, owners);
					}
					if (owners.indexOf(groupIndex) < 0) owners.push(groupIndex);
				}
			}
		}
		var unassigned = new SeparateObjectGroup("Unassigned");
		for (face in faces) {
			var faceOwners = new Array<Array<Bool>>();
			for (_ in 0...3) {
				var owners = new Array<Bool>();
				for (_ in 0...groups.length) owners.push(false);
				faceOwners.push(owners);
			}
			var vertices = [face.a, face.b, face.c];
			var topology = [face.topologyA, face.topologyB, face.topologyC];
			for (corner in 0...3) {
				var vertex = vertices[corner];
				var offset = vertex * stride;
				if (vertex < 0 || offset + 2 >= positions.length)
					throw "Mesh index is outside the vertex position array.";
				var owners = topology[corner] >= 0 ? topologyOwners.get(topology[corner]) : null;
				if (owners == null && meshGroups == null) {
					owners = vertexOwners.get(
						positions[offset] + "," + positions[offset + 1] + "," + positions[offset + 2]
					);
				}
				if (owners != null) for (owner in owners) faceOwners[corner][owner] = true;
			}
			var assignedToGroup = false;
			for (groupIndex in 0...groups.length) {
				if (faceOwners[0][groupIndex] && faceOwners[1][groupIndex] && faceOwners[2][groupIndex]) {
					groups[groupIndex].faces.push(face);
					assignedToGroup = true;
				}
			}
			if (!assignedToGroup) unassigned.faces.push(face);
		}
		var nonempty = new Array<SeparateObjectGroup>();
		for (group in groups) if (group.faces.length > 0) nonempty.push(group);
		if (unassigned.faces.length > 0) nonempty.push(unassigned);
		return nonempty;
	}

	static function createSeparatedObject(mesh: MeshObject, group: SeparateObjectGroup): MeshObject {
		var vertexRemap = new Map<Int, Int>();
		var sourceVertices = new Array<Int>();
		var materialIndices = new Array<Array<Int>>();
		var indexArrays = new Array<TIndexArray>();
		for (material in 0...mesh.materials.length) materialIndices.push([]);
		function remapVertex(sourceIndex: Int): Int {
			if (sourceIndex < 0) throw "Mesh contains a negative vertex index.";
			if (!vertexRemap.exists(sourceIndex)) {
				vertexRemap.set(sourceIndex, sourceVertices.length);
				sourceVertices.push(sourceIndex);
			}
			return vertexRemap.get(sourceIndex);
		}
		for (face in group.faces) {
			if (face.material < 0 || face.material >= materialIndices.length)
				throw 'Mesh face references invalid material slot ${face.material}.';
			var indices = materialIndices[face.material];
			indices.push(remapVertex(face.a));
			indices.push(remapVertex(face.b));
			indices.push(remapVertex(face.c));
		}
		for (material in 0...materialIndices.length) {
			var values = materialIndices[material];
			if (values.length == 0) continue;
			var packed = new Uint32Array(values.length);
			for (i in 0...values.length) packed[i] = values[i];
			indexArrays.push({ values: packed, material: material });
		}

		var positionArray: TVertexArray = null;
		for (array in mesh.data.raw.vertex_arrays) if (array.attrib == "pos") positionArray = array;
		if (positionArray == null || positionArray.values == null) throw 'Mesh "${mesh.name}" has no packed positions.';
		var sourcePositions: Int16Array = positionArray.values;
		var positionStride = positionArray.size == null || positionArray.size <= 0 ? 4 : positionArray.size;
		var minX = Math.POSITIVE_INFINITY;
		var minY = Math.POSITIVE_INFINITY;
		var minZ = Math.POSITIVE_INFINITY;
		var maxX = Math.NEGATIVE_INFINITY;
		var maxY = Math.NEGATIVE_INFINITY;
		var maxZ = Math.NEGATIVE_INFINITY;
		var localPositions = new Array<CSGVector>();
		for (sourceIndex in sourceVertices) {
			var offset = sourceIndex * positionStride;
			if (offset < 0 || offset + 2 >= sourcePositions.length)
				throw "Mesh vertex index is outside the position attribute.";
			var point = new CSGVector(
				sourcePositions[offset] / 32767.0 * mesh.data.scalePos,
				sourcePositions[offset + 1] / 32767.0 * mesh.data.scalePos,
				sourcePositions[offset + 2] / 32767.0 * mesh.data.scalePos
			);
			localPositions.push(point);
			minX = Math.min(minX, point.x);
			minY = Math.min(minY, point.y);
			minZ = Math.min(minZ, point.z);
			maxX = Math.max(maxX, point.x);
			maxY = Math.max(maxY, point.y);
			maxZ = Math.max(maxZ, point.z);
		}
		var center = new CSGVector((minX + maxX) * 0.5, (minY + maxY) * 0.5, (minZ + maxZ) * 0.5);
		var dimensions = new Vec4(maxX - minX, maxY - minY, maxZ - minZ);
		var scalePos = 0.0;
		for (point in localPositions) {
			point.x -= center.x;
			point.y -= center.y;
			point.z -= center.z;
			scalePos = Math.max(scalePos, Math.abs(point.x));
			scalePos = Math.max(scalePos, Math.abs(point.y));
			scalePos = Math.max(scalePos, Math.abs(point.z));
		}
		if (scalePos < 1e-8) scalePos = 1.0;

		var vertexArrays = new Array<TVertexArray>();
		for (array in mesh.data.raw.vertex_arrays) {
			var sourceValues: Int16Array = array.values;
			if (sourceValues == null) throw 'Mesh vertex attribute "${array.attrib}" has no data.';
			var attributeStride = array.size != null && array.size > 0
				? array.size
				: (array.data == "short2norm" ? 2 : 4) - (array.padding == null ? 0 : array.padding);
			var packedValues = new Int16Array(sourceVertices.length * attributeStride);
			for (i in 0...sourceVertices.length) {
				var sourceOffset = sourceVertices[i] * attributeStride;
				if (sourceOffset < 0 || sourceOffset + attributeStride > sourceValues.length)
					throw 'Mesh vertex index is outside the "${array.attrib}" attribute.';
				for (j in 0...attributeStride) packedValues[i * attributeStride + j] = sourceValues[sourceOffset + j];
				if (array.attrib == "pos") {
					if (attributeStride < 3) throw "Mesh position attribute has fewer than three components.";
					packedValues[i * attributeStride] = toShort(localPositions[i].x / scalePos);
					packedValues[i * attributeStride + 1] = toShort(localPositions[i].y / scalePos);
					packedValues[i * attributeStride + 2] = toShort(localPositions[i].z / scalePos);
				}
			}
			vertexArrays.push({
				attrib: array.attrib,
				values: packedValues,
				data: array.data,
				padding: array.padding,
				size: array.size
			});
		}
		var raw: TMeshData = {
			name: mesh.data.raw.name + "_" + group.name,
			sorting_index: mesh.data.raw.sorting_index,
			vertex_arrays: vertexArrays,
			index_arrays: indexArrays,
			scale_pos: scalePos,
			scale_tex: mesh.data.scaleTex
		};
		var data = new MeshData(raw, function(_: MeshData) {});
		var part = Scene.active.addMeshObject(
			data, mesh.materials, mesh.parent != null ? mesh.parent : Scene.active.root
		);
		part.name = mesh.name + "_" + group.name;
		var packedDimensions = new kha.arrays.Float32Array(3);
		packedDimensions[0] = dimensions.x;
		packedDimensions[1] = dimensions.y;
		packedDimensions[2] = dimensions.z;
		part.raw = cast { name: part.name, type: "mesh_object", dimensions: packedDimensions };
		part.transform.loc.set(
			mesh.transform.loc.x + center.x * mesh.transform.local._00 + center.y * mesh.transform.local._10 + center.z * mesh.transform.local._20,
			mesh.transform.loc.y + center.x * mesh.transform.local._01 + center.y * mesh.transform.local._11 + center.z * mesh.transform.local._21,
			mesh.transform.loc.z + center.x * mesh.transform.local._02 + center.y * mesh.transform.local._12 + center.z * mesh.transform.local._22
		);
		part.transform.rot.setFrom(mesh.transform.rot);
		part.transform.scale.setFrom(mesh.transform.scale);
		part.transform.buildMatrix();
		var bounds = orientedWorldBounds(localPositions, part.transform.world);
		part.transform.dim.set(bounds.x, bounds.y, bounds.z);
		part.addTrait(new armory.trait.internal.UniformsManager());
		return part;
	}

	static function orientedWorldBounds(points: Array<CSGVector>, matrix: Mat4): CSGVector {
		var axes = [
			new CSGVector(matrix._00, matrix._01, matrix._02),
			new CSGVector(matrix._10, matrix._11, matrix._12),
			new CSGVector(matrix._20, matrix._21, matrix._22)
		];
		for (i in 0...axes.length) {
			var length = axes[i].length();
			if (length < 1e-8) axes[i] = i == 0
				? new CSGVector(1, 0, 0)
				: (i == 1 ? new CSGVector(0, 1, 0) : new CSGVector(0, 0, 1));
			else axes[i] = axes[i].times(1.0 / length);
		}
		var minimum = [Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY];
		var maximum = [Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY];
		for (point in points) {
			var world = new CSGVector(
				point.x * matrix._00 + point.y * matrix._10 + point.z * matrix._20 + matrix._30,
				point.x * matrix._01 + point.y * matrix._11 + point.z * matrix._21 + matrix._31,
				point.x * matrix._02 + point.y * matrix._12 + point.z * matrix._22 + matrix._32
			);
			for (i in 0...3) {
				var projection = world.x * axes[i].x + world.y * axes[i].y + world.z * axes[i].z;
				minimum[i] = Math.min(minimum[i], projection);
				maximum[i] = Math.max(maximum[i], projection);
			}
		}
		return new CSGVector(maximum[0] - minimum[0], maximum[1] - minimum[1], maximum[2] - minimum[2]);
	}

	static function meshToPolygons(mesh: MeshObject, materialOffset: Int): Array<CSGPolygon> {
		mesh.transform.update();
		var positionArray = mesh.data.geom.positions;
		if (positionArray == null || positionArray.values == null) throw 'Mesh "${mesh.name}" has no position data.';
		var values: Int16Array = positionArray.values;
		var stride = positionArray.size == null || positionArray.size <= 0 ? 4 : positionArray.size;
		var uvArray = mesh.data.geom.uvs;
		var uvValues: Int16Array = uvArray == null ? null : uvArray.values;
		var uvStride = uvArray == null || uvArray.size == null || uvArray.size <= 0 ? 2 : uvArray.size;
		var uvScale = mesh.data.scaleTex;
		var matrix = mesh.transform.worldUnpack;
		var triangles = new Array<CSGIndexedTriangle>();

		for (groupIndex in 0...mesh.data.geom.indices.length) {
			var indices = mesh.data.geom.indices[groupIndex];
			var material = groupIndex < mesh.data.geom.materialIndices.length
				? mesh.data.geom.materialIndices[groupIndex]
				: groupIndex;
			var shared = materialOffset + material;
			for (i in 0...Std.int(indices.length / 3)) {
				var offset = i * 3;
				triangles.push(new CSGIndexedTriangle(indices[offset], indices[offset + 1], indices[offset + 2], shared));
			}
		}
		var parents = new Array<Int>();
		for (i in 0...triangles.length) parents.push(i);
		var edgeOwners = new Map<String, Int>();
		for (i in 0...triangles.length) {
			var triangle = triangles[i];
			connectEdge(edgeOwners, parents, i, positionKey(values, stride, triangle.a), positionKey(values, stride, triangle.b));
			connectEdge(edgeOwners, parents, i, positionKey(values, stride, triangle.b), positionKey(values, stride, triangle.c));
			connectEdge(edgeOwners, parents, i, positionKey(values, stride, triangle.c), positionKey(values, stride, triangle.a));
		}
		var volumes = new Map<Int, Float>();
		for (i in 0...triangles.length) {
			var triangle = triangles[i];
			var p0 = readWorldPoint(values, stride, triangle.a, matrix);
			var p1 = readWorldPoint(values, stride, triangle.b, matrix);
			var p2 = readWorldPoint(values, stride, triangle.c, matrix);
			var volume = p0.dot(p1.cross(p2)) / 6.0;
			var root = findRoot(parents, i);
			volumes.set(root, (volumes.exists(root) ? volumes.get(root) : 0.0) + volume);
		}
		var polygons = new Array<CSGPolygon>();
		for (i in 0...triangles.length) {
			var triangle = triangles[i];
			var indexA = triangle.a;
			var indexB = triangle.b;
			var indexC = triangle.c;
			if (volumes.get(findRoot(parents, i)) < 0) {
				var temp = indexB;
				indexB = indexC;
				indexC = temp;
			}
			var va = new CSGVertex(readWorldPoint(values, stride, indexA, matrix), null, readUV(uvValues, uvStride, indexA, uvScale));
			var vb = new CSGVertex(readWorldPoint(values, stride, indexB, matrix), null, readUV(uvValues, uvStride, indexB, uvScale));
			var vc = new CSGVertex(readWorldPoint(values, stride, indexC, matrix), null, readUV(uvValues, uvStride, indexC, uvScale));
			var normal = vb.pos.minus(va.pos).cross(vc.pos.minus(va.pos));
			if (normal.length() < 1e-10) trace('Mesh "${mesh.name}" contains a degenerate triangle.');
			polygons.push(new CSGPolygon([va, vb, vc], triangle.material));
		}
		return polygons;
	}

	static function readUV(values: Int16Array, stride: Int, index: Int, scale: Float): CSGVector {
		if (values == null) return null;
		var offset = index * stride;
		if (index < 0 || offset + 1 >= values.length) throw "Mesh UV index is outside the vertex array.";
		return new CSGVector(values[offset] / 32767.0 * scale, values[offset + 1] / 32767.0 * scale, 0);
	}

	static function readWorldPoint(values: Int16Array, stride: Int, index: Int, matrix: iron.math.Mat4): CSGVector {
		var offset = index * stride;
		if (index < 0 || offset + 2 >= values.length) throw "Mesh position index is outside the vertex array.";
		var x = values[offset] / 32767.0;
		var y = values[offset + 1] / 32767.0;
		var z = values[offset + 2] / 32767.0;
		var point = new CSGVector(
			x * matrix._00 + y * matrix._10 + z * matrix._20 + matrix._30,
			x * matrix._01 + y * matrix._11 + z * matrix._21 + matrix._31,
			x * matrix._02 + y * matrix._12 + z * matrix._22 + matrix._32
		);
		if (!isFiniteNumber(point.x) || !isFiniteNumber(point.y) || !isFiniteNumber(point.z))
			throw "Mesh contains a non-finite world-space vertex.";
		return point;
	}

	static function polygonsToObject(polygons: Array<CSGPolygon>, materials: Vector<MaterialData>, name: String, reference: MeshObject): MeshObject {
		reference.transform.update();
		var referenceLocation = new Vec4();
		var referenceRotation = new Quat();
		var referenceScale = new Vec4();
		reference.transform.world.decompose(referenceLocation, referenceRotation, referenceScale);
		var rotation = Mat4.identity();
		rotation.fromQuat(referenceRotation);

		var minX = Math.POSITIVE_INFINITY;
		var minY = Math.POSITIVE_INFINITY;
		var minZ = Math.POSITIVE_INFINITY;
		var maxX = Math.NEGATIVE_INFINITY;
		var maxY = Math.NEGATIVE_INFINITY;
		var maxZ = Math.NEGATIVE_INFINITY;
		for (polygon in polygons) for (vertex in polygon.vertices) {
			var point = worldToFrame(vertex.pos, referenceLocation, rotation);
			minX = Math.min(minX, point.x);
			minY = Math.min(minY, point.y);
			minZ = Math.min(minZ, point.z);
			maxX = Math.max(maxX, point.x);
			maxY = Math.max(maxY, point.y);
			maxZ = Math.max(maxZ, point.z);
		}
		var centerX = (minX + maxX) * 0.5;
		var centerY = (minY + maxY) * 0.5;
		var centerZ = (minZ + maxZ) * 0.5;
		var centerWorld = frameToWorld(new CSGVector(centerX, centerY, centerZ), referenceLocation, rotation);
		var scale = Math.max(maxX - minX, Math.max(maxY - minY, maxZ - minZ)) * 0.5;
		if (scale < 1e-6) scale = 1.0;

		var grouped = new Map<Int, Array<Int>>();
		var positions = new Array<Float>();
		var normals = new Array<Float>();
		var uvs = new Array<Float>();
		for (polygon in polygons) {
			for (i in 1...(polygon.vertices.length - 1)) {
				var va = polygon.vertices[0];
				var vb = polygon.vertices[i];
				var vc = polygon.vertices[i + 1];
				var a = worldToFrame(va.pos, referenceLocation, rotation);
				var b = worldToFrame(vb.pos, referenceLocation, rotation);
				var c = worldToFrame(vc.pos, referenceLocation, rotation);
				a = a.minus(new CSGVector(centerX, centerY, centerZ));
				b = b.minus(new CSGVector(centerX, centerY, centerZ));
				c = c.minus(new CSGVector(centerX, centerY, centerZ));
				var localPoints = [a, b, c];
				var sourceVertices = [va, vb, vc];
				var normal = b.minus(a).cross(c.minus(a));
				var normalLength = normal.length();
				if (normalLength < 1e-8) continue;
				normal = normal.times(1.0 / normalLength);
				var faceIndices = grouped.get(polygon.shared);
				if (faceIndices == null) {
					faceIndices = [];
					grouped.set(polygon.shared, faceIndices);
				}
				for (pointIndex in 0...3) {
					var point = localPoints[pointIndex];
					var vertex = sourceVertices[pointIndex];
					var vertexIndex = Std.int(positions.length / 3);
					positions.push(point.x);
					positions.push(point.y);
					positions.push(point.z);
					normals.push(normal.x);
					normals.push(normal.y);
					normals.push(normal.z);
					if (vertex.uv != null) {
						uvs.push(vertex.uv.x);
						uvs.push(vertex.uv.y);
					}
					else {
						var absX = Math.abs(normal.x);
						var absY = Math.abs(normal.y);
						var absZ = Math.abs(normal.z);
						if (absX >= absY && absX >= absZ) {
							uvs.push(point.z / scale);
							uvs.push(point.y / scale);
						}
						else if (absY >= absZ) {
							uvs.push(point.x / scale);
							uvs.push(point.z / scale);
						}
						else {
							uvs.push(point.x / scale);
							uvs.push(point.y / scale);
						}
					}
					faceIndices.push(vertexIndex);
				}
			}
		}
		if (positions.length == 0) return null;

		var vertexCount = Std.int(positions.length / 3);
		var uvScale = 1.0;
		for (uv in uvs) uvScale = Math.max(uvScale, Math.abs(uv));
		var packedPositions = new Int16Array(vertexCount * 4);
		var packedNormals = new Int16Array(vertexCount * 2);
		var packedTangents = new Int16Array(vertexCount * 4);
		var packedUvs = new Int16Array(vertexCount * 2);
		for (i in 0...vertexCount) {
			packedPositions[i * 4] = toShort(positions[i * 3] / scale);
			packedPositions[i * 4 + 1] = toShort(positions[i * 3 + 1] / scale);
			packedPositions[i * 4 + 2] = toShort(positions[i * 3 + 2] / scale);
			packedPositions[i * 4 + 3] = toShort(normals[i * 3 + 2]);
			packedNormals[i * 2] = toShort(normals[i * 3]);
			packedNormals[i * 2 + 1] = toShort(normals[i * 3 + 1]);
			var normal = new CSGVector(normals[i * 3], normals[i * 3 + 1], normals[i * 3 + 2]);
			var tangent = Math.abs(normal.x) < 0.9
				? normal.cross(new CSGVector(1, 0, 0)).unit()
				: normal.cross(new CSGVector(0, 1, 0)).unit();
			packedTangents[i * 4] = toShort(tangent.x);
			packedTangents[i * 4 + 1] = toShort(tangent.y);
			packedTangents[i * 4 + 2] = toShort(tangent.z);
			packedTangents[i * 4 + 3] = 32767;
			packedUvs[i * 2] = toShort(uvs[i * 2] / uvScale);
			packedUvs[i * 2 + 1] = toShort(uvs[i * 2 + 1] / uvScale);
		}
		var indexArrays = new Array<TIndexArray>();
		for (material in grouped.keys()) {
			if (material < 0 || material >= materials.length) throw 'CSG result refers to missing material slot $material.';
			var source = grouped.get(material);
			var packedIndices = new Uint32Array(source.length);
			for (i in 0...source.length) packedIndices[i] = source[i];
			indexArrays.push({ values: packedIndices, material: material });
		}
		var vertexArrays: Array<TVertexArray> = [
			{ attrib: "pos", values: packedPositions, data: "short4norm" },
			{ attrib: "nor", values: packedNormals, data: "short2norm" },
			{ attrib: "tex", values: packedUvs, data: "short2norm" },
			{ attrib: "tang", values: packedTangents, data: "short4norm" }
		];
		var raw: TMeshData = {
			name: name,
			sorting_index: 0,
			vertex_arrays: vertexArrays,
			index_arrays: indexArrays,
			scale_pos: scale,
			scale_tex: uvScale
		};
		var data = new MeshData(raw, function(_: MeshData) {});
		data.geom.calculateAABB();
		var result = Scene.active.addMeshObject(data, materials, Scene.active.root);
		result.name = name;
		var dimensions = new kha.arrays.Float32Array(3);
		dimensions[0] = maxX - minX;
		dimensions[1] = maxY - minY;
		dimensions[2] = maxZ - minZ;
		result.raw = cast { name: name, type: "mesh_object", dimensions: dimensions };
		result.transform.loc.set(centerWorld.x, centerWorld.y, centerWorld.z);
		result.transform.rot.setFrom(referenceRotation);
		result.transform.localOnly = true;
		result.transform.buildMatrix();
		result.transform.dim.set(dimensions[0], dimensions[1], dimensions[2]);
		result.addTrait(new armory.trait.internal.UniformsManager());
		return result;
	}

	static function worldToFrame(point: CSGVector, origin: Vec4, rotation: Mat4): CSGVector {
		var x = point.x - origin.x;
		var y = point.y - origin.y;
		var z = point.z - origin.z;
		return new CSGVector(
			x * rotation._00 + y * rotation._01 + z * rotation._02,
			x * rotation._10 + y * rotation._11 + z * rotation._12,
			x * rotation._20 + y * rotation._21 + z * rotation._22
		);
	}

	static function frameToWorld(point: CSGVector, origin: Vec4, rotation: Mat4): CSGVector {
		return new CSGVector(
			point.x * rotation._00 + point.y * rotation._10 + point.z * rotation._20 + origin.x,
			point.x * rotation._01 + point.y * rotation._11 + point.z * rotation._21 + origin.y,
			point.x * rotation._02 + point.y * rotation._12 + point.z * rotation._22 + origin.z
		);
	}

	static function connectEdge(owners: Map<String, Int>, parents: Array<Int>, face: Int, a: String, b: String) {
		var edge = a < b ? a + "|" + b : b + "|" + a;
		var owner = owners.get(edge);
		if (owner == null) owners.set(edge, face);
		else joinRoots(parents, face, owner);
	}

	static function positionKey(values: Int16Array, stride: Int, index: Int): String {
		var offset = index * stride;
		if (index < 0 || offset + 2 >= values.length) throw "Mesh index is outside the vertex position array.";
		return values[offset] + "," + values[offset + 1] + "," + values[offset + 2];
	}

	static function topologyKey(index: Int, topologyIndex: Int, positions: Int16Array, stride: Int): String {
		return topologyIndex >= 0 ? "v" + topologyIndex : "p" + positionKey(positions, stride, index);
	}

	static function findRoot(parents: Array<Int>, value: Int): Int {
		var root = value;
		while (parents[root] != root) root = parents[root];
		while (parents[value] != value) {
			var next = parents[value];
			parents[value] = root;
			value = next;
		}
		return root;
	}

	static function joinRoots(parents: Array<Int>, a: Int, b: Int) {
		var rootA = findRoot(parents, a);
		var rootB = findRoot(parents, b);
		if (rootA != rootB) parents[rootB] = rootA;
	}

	static function toShort(value: Float): Int {
		return Std.int(Math.round(Math.max(-1.0, Math.min(1.0, value)) * 32767.0));
	}

	static inline function isFiniteNumber(value: Float): Bool {
		return !Math.isNaN(value) && value != Math.POSITIVE_INFINITY && value != Math.NEGATIVE_INFINITY;
	}
}

private class CSGVector {
	public var x: Float;
	public var y: Float;
	public var z: Float;

	public function new(x: Float, y: Float, z: Float) {
		this.x = x;
		this.y = y;
		this.z = z;
	}

	public function clone(): CSGVector return new CSGVector(x, y, z);
	public function negated(): CSGVector return new CSGVector(-x, -y, -z);
	public function plus(v: CSGVector): CSGVector return new CSGVector(x + v.x, y + v.y, z + v.z);
	public function minus(v: CSGVector): CSGVector return new CSGVector(x - v.x, y - v.y, z - v.z);
	public function times(s: Float): CSGVector return new CSGVector(x * s, y * s, z * s);
	public function dot(v: CSGVector): Float return x * v.x + y * v.y + z * v.z;
	public function length(): Float return Math.sqrt(dot(this));
	public function unit(): CSGVector return times(1.0 / length());
	public function lerp(v: CSGVector, t: Float): CSGVector return plus(v.minus(this).times(t));
	public function cross(v: CSGVector): CSGVector {
		return new CSGVector(y * v.z - z * v.y, z * v.x - x * v.z, x * v.y - y * v.x);
	}
}

private class CSGVertex {
	public var pos: CSGVector;
	public var normal: CSGVector;
	public var uv: CSGVector;

	public function new(pos: CSGVector, normal: CSGVector = null, uv: CSGVector = null) {
		this.pos = pos;
		this.normal = normal == null ? new CSGVector(0, 0, 0) : normal;
		this.uv = uv;
	}

	public function clone(): CSGVertex return new CSGVertex(pos.clone(), normal.clone(), uv == null ? null : uv.clone());
	public function flip() normal = normal.negated();
	public function interpolate(other: CSGVertex, t: Float): CSGVertex {
		return new CSGVertex(
			pos.lerp(other.pos, t),
			normal.lerp(other.normal, t),
			uv == null || other.uv == null ? null : uv.lerp(other.uv, t)
		);
	}
}

private class CSGPolygon {
	public static inline var EPSILON = 1e-5;
	public var vertices: Array<CSGVertex>;
	public var shared: Int;
	public var plane: CSGPlane;

	public function new(vertices: Array<CSGVertex>, shared: Int) {
		this.vertices = vertices;
		this.shared = shared;
		plane = CSGPlane.fromPoints(vertices[0].pos, vertices[1].pos, vertices[2].pos);
	}

	public function clone(): CSGPolygon {
		return new CSGPolygon([for (vertex in vertices) vertex.clone()], shared);
	}

	public function flip() {
		vertices.reverse();
		for (vertex in vertices) vertex.flip();
		plane.flip();
	}
}

private class CSGPlane {
	public var normal: CSGVector;
	public var w: Float;

	public function new(normal: CSGVector, w: Float) {
		this.normal = normal;
		this.w = w;
	}

	public static function fromPoints(a: CSGVector, b: CSGVector, c: CSGVector): CSGPlane {
		var normal = b.minus(a).cross(c.minus(a)).unit();
		return new CSGPlane(normal, normal.dot(a));
	}

	public function clone(): CSGPlane return new CSGPlane(normal.clone(), w);
	public function flip() {
		normal = normal.negated();
		w = -w;
	}

	public function splitPolygon(
		polygon: CSGPolygon,
		coplanarFront: Array<CSGPolygon>,
		coplanarBack: Array<CSGPolygon>,
		front: Array<CSGPolygon>,
		back: Array<CSGPolygon>
	) {
		var polygonType = 0;
		var types = new Array<Int>();
		for (vertex in polygon.vertices) {
			var distance = normal.dot(vertex.pos) - w;
			var type = distance < -CSGPolygon.EPSILON ? 2 : distance > CSGPolygon.EPSILON ? 1 : 0;
			polygonType |= type;
			types.push(type);
		}
		switch (polygonType) {
			case 0:
				(normal.dot(polygon.plane.normal) > 0 ? coplanarFront : coplanarBack).push(polygon);
			case 1:
				front.push(polygon);
			case 2:
				back.push(polygon);
			case 3:
				var f = new Array<CSGVertex>();
				var b = new Array<CSGVertex>();
				for (i in 0...polygon.vertices.length) {
					var j = (i + 1) % polygon.vertices.length;
					var ti = types[i];
					var tj = types[j];
					var vi = polygon.vertices[i];
					var vj = polygon.vertices[j];
					if (ti != 2) f.push(vi);
					if (ti != 1) b.push(ti != 2 ? vi.clone() : vi);
					if ((ti | tj) == 3) {
						var t = (w - normal.dot(vi.pos)) / normal.dot(vj.pos.minus(vi.pos));
						var vertex = vi.interpolate(vj, t);
						f.push(vertex);
						b.push(vertex.clone());
					}
				}
				if (f.length >= 3) front.push(new CSGPolygon(f, polygon.shared));
				if (b.length >= 3) back.push(new CSGPolygon(b, polygon.shared));
		}
	}
}

private class CSGNode {
	public var plane: CSGPlane = null;
	public var front: CSGNode = null;
	public var back: CSGNode = null;
	public var polygons: Array<CSGPolygon> = [];

	public function new(?polygons: Array<CSGPolygon>) {
		if (polygons != null) build(polygons);
	}

	public function invert() {
		for (polygon in polygons) polygon.flip();
		if (plane != null) plane.flip();
		if (front != null) front.invert();
		if (back != null) back.invert();
		var temp = front;
		front = back;
		back = temp;
	}

	public function clipPolygons(input: Array<CSGPolygon>): Array<CSGPolygon> {
		if (plane == null) return input.copy();
		var frontPolygons = new Array<CSGPolygon>();
		var backPolygons = new Array<CSGPolygon>();
		for (polygon in input) plane.splitPolygon(polygon, frontPolygons, backPolygons, frontPolygons, backPolygons);
		if (front != null) frontPolygons = front.clipPolygons(frontPolygons);
		if (back != null) backPolygons = back.clipPolygons(backPolygons);
		else backPolygons = [];
		return frontPolygons.concat(backPolygons);
	}

	public function clipTo(other: CSGNode) {
		polygons = other.clipPolygons(polygons);
		if (front != null) front.clipTo(other);
		if (back != null) back.clipTo(other);
	}

	public function allPolygons(): Array<CSGPolygon> {
		var result = polygons.copy();
		if (front != null) result = result.concat(front.allPolygons());
		if (back != null) result = result.concat(back.allPolygons());
		return result;
	}

	public function build(input: Array<CSGPolygon>) {
		if (input.length == 0) return;
		if (plane == null) plane = input[0].plane.clone();
		var frontPolygons = new Array<CSGPolygon>();
		var backPolygons = new Array<CSGPolygon>();
		for (polygon in input) plane.splitPolygon(polygon, polygons, polygons, frontPolygons, backPolygons);
		if (frontPolygons.length > 0) {
			if (front == null) front = new CSGNode();
			front.build(frontPolygons);
		}
		if (backPolygons.length > 0) {
			if (back == null) back = new CSGNode();
			back.build(backPolygons);
		}
	}
}

private class CSGIndexedTriangle {
	public var a: Int;
	public var b: Int;
	public var c: Int;
	public var material: Int;
	public var topologyA: Int;
	public var topologyB: Int;
	public var topologyC: Int;

	public function new(a: Int, b: Int, c: Int, material: Int, topologyA: Int = -1, topologyB: Int = -1, topologyC: Int = -1) {
		this.a = a;
		this.b = b;
		this.c = c;
		this.material = material;
		this.topologyA = topologyA;
		this.topologyB = topologyB;
		this.topologyC = topologyC;
	}
}

private class SeparateObjectGroup {
	public var name: String;
	public var faces: Array<CSGIndexedTriangle> = [];

	public function new(name: String) {
		this.name = name;
	}
}
