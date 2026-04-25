package armory.trait;

import iron.math.Vec4;
import iron.math.Mat4;
import iron.Trait;
import iron.object.Object;
import iron.object.MeshObject;
import iron.data.MeshData;
import iron.data.SceneFormat;
#if arm_bullet
import armory.trait.physics.bullet.RigidBody;
import armory.trait.physics.PhysicsWorld;
#end

import armory.object.MeshDataExtension;
import kha.arrays.Float32Array;
import haxe.ds.Vector;

class PhysicsBreak extends Trait {

#if (!arm_bullet)
	public function new() { super(); }
#else

	// Track all debris for cleanup on scene change
	static var allDebris: Array<MeshObject> = [];
	static var sceneCallbackRegistered = false;

	var breaker: ConvexBreaker;
	var physics: PhysicsWorld;
	var body: RigidBody;

	@prop
	var fractureImpulse: Float = 0.1;
	@prop
	var fractureIterative: Bool = true;
	@prop
	var traitName: String = '';

	@prop
	var subdivideByPlane: Bool = false;
	
	@prop
	var plane: Vec4 = new Vec4(1, 1, 1);

	@prop
	var randomPlane: Bool = true;

	public function new() {
		super();

		breaker = new ConvexBreaker(0.1);
		notifyOnInit(init);
	}

	function init() {
		physics = armory.trait.physics.PhysicsWorld.active;
		if (physics == null) return;

		body = object.getTrait(RigidBody);
		breaker.initBreakableObject(cast object, body.mass, body.friction, new Vec4(), new Vec4(), true);

		// Register scene removal callback once
		if (!sceneCallbackRegistered) {
			sceneCallbackRegistered = true;
			iron.Scene.active.notifyOnRemove(cleanupAllDebris);
		}

		notifyOnUpdate(update);
	}

	static function cleanupAllDebris() {
		// Make a copy since remove() modifies the array
		var toRemove = allDebris.copy();
		for (debris in toRemove) {
			if (debris != null) debris.remove();
		}
		allDebris = [];
		sceneCallbackRegistered = false;
	}

	function update() {
		if (body == null || !body.ready || physics == null) return;

		var ar = physics.getContactPairs(body);
		if (ar != null) {
			var maxImpulse: Float = 0.0;
			var impactPoint: Vec4 = null;
			var impactNormal: Vec4 = null;
			for (p in ar) {
				if (maxImpulse < p.impulse) {
					maxImpulse = p.impulse;
					impactPoint = p.posB;
					impactNormal = p.normOnB;
				}
			}

			var fractureImpulse = 4.0;
			if (maxImpulse > fractureImpulse) {
				var radialIter = 1;
				var randIter = 1;
				var debris = subdivideByPlane ? breaker.subdivideByPlane(cast object, plane, randomPlane) :
					breaker.subdivideByImpact(cast object, impactPoint, impactNormal, radialIter, randIter);
				for (o in debris) {
					var obj: Object = cast o;
					obj.name = o.data.raw.name;
					obj.setParent(iron.Scene.active.root);
					
					var dims = new kha.arrays.Float32Array(3);
					dims[0] = o.data.geom.aabb.x;
					dims[1] = o.data.geom.aabb.y;
					dims[2] = o.data.geom.aabb.z;

					obj.raw = cast { 
					    type: "mesh_object", 
					    name: obj.name, 
					    data_ref: obj.name,
					    dimensions: dims
					};

					if (traitName == '')
						for (t in object.traits) {
							var tc = Type.getClass(t);
							if (tc == null || tc == armory.trait.physics.bullet.RigidBody || 
								tc == armory.trait.PhysicsBreak || Type.resolveClass("arm.PhysicsBreak") != null) continue;

							var nt = Type.createInstance(tc, []);
							for (f in Type.getInstanceFields(tc)) {
								var v = Reflect.field(t, f);
								if (v != null && !Reflect.isFunction(v)) Reflect.setField(nt, f, v);
							}
							obj.addTrait(nt);
						}
					else {
						var cname = Type.resolveClass(Main.projectPackage + "." + traitName);
						if (cname == null) cname = Type.resolveClass(Main.projectPackage + ".node." + traitName);
						var trait = Type.createInstance(cname, []);
						obj.addTrait(trait);

						obj.addTrait(new armory.trait.internal.UniformsManager());
					}

					var ud = breaker.userDataMap.get(cast o);
					if (ud == null) continue;
					var params: RigidBodyParams = {
						linearDamping: 0.04,
						angularDamping: 0.1,
						angularFriction: 0.1,
						linearFactorsX: 1.0,
						linearFactorsY: 1.0,
						linearFactorsZ: 1.0,
						angularFactorsX: 1.0,
						angularFactorsY: 1.0,
						angularFactorsZ: 1.0,
						collisionMargin: 0.04,
						linearDeactivationThreshold: 0.0,
						angularDeactivationThreshold: 0.0,
						deactivationTime: 0.0
					};

					obj.addTrait(new RigidBody(Shape.ConvexHull, ud.mass, ud.friction, 0, 1, params));
					if (fractureIterative && cast(o, MeshObject).data.geom.positions.values.length > 100) {
						var pb = new PhysicsBreak();
						pb.fractureImpulse = fractureImpulse / 2;
						pb.traitName = traitName;
						obj.addTrait(pb);
					}
					// Track debris for cleanup on scene change
					allDebris.push(cast o);
				}

				// Remove self from update before removing object
				remove();
				object.remove();
			}
		}
	}

#end
}

// Based on work by yomboprime https://github.com/yomboprime
// This class can be used to subdivide a convex geometry object into pieces
class ConvexBreaker {

	var minSizeForBreak: Float;
	var smallDelta: Float;

	var tempLine: Line3;
	var tempPlane: Plane;
	var tempPlane2: Plane;
	var tempCM1: Vec4;
	var tempCM2: Vec4;
	var tempVec4: Vec4;
	var tempVec42: Vec4;
	var tempVec43: Vec4;
	var tempCutResult: CutResult;
	var segments: Array<Bool>;

	public var userDataMap: Map<MeshObject, UserData>;

	// minSizeForBreak Min size a debris can have to break
	// smallDelta Max distance to consider that a point belongs to a plane
	public function new(minSizeForBreak = 1.4, smallDelta = 0.0001) {
		this.minSizeForBreak = minSizeForBreak;
		this.smallDelta = smallDelta;
		tempLine = new Line3();
		tempPlane = new Plane();
		tempPlane2 = new Plane();
		tempCM1 = new Vec4();
		tempCM2 = new Vec4();
		tempVec4 = new Vec4();
		tempVec42 = new Vec4();
		tempVec43 = new Vec4();
		tempCutResult = new CutResult();
		segments = new Array<Bool>();
		var n = 30 * 30;
		for (i in 0...n) segments.push(false);
		userDataMap = new Map();
	}

	public function initBreakableObject(object: MeshObject, mass: Float, friction: Float, velocity: Vec4, angularVelocity: Vec4, breakable: Bool) {
		var ar = object.data.geom.positions.values;
		var scalePos = object.data.scalePos;
		// Create vertices mark
		var sc = object.transform.scale;
		var vertices = new Array<Vec4>();
		for (i in 0...Std.int(ar.length / 4)) {
			// Use w component as mark
			vertices.push(new Vec4(
				ar[i * 4    ] * sc.x * (1 / 32767) * scalePos,
				ar[i * 4 + 1] * sc.y * (1 / 32767) * scalePos,
				ar[i * 4 + 2] * sc.z * (1 / 32767) * scalePos,
				0
			));
		}

		var faces = new Array<Face3>();
		
		for (materialIndex in 0...object.data.geom.indices.length) {
			var ind = object.data.geom.indices[materialIndex];
			for (i in 0...Std.int(ind.length / 3)) {
				var a = ind[i * 3];
				var b = ind[i * 3 + 1];
				var c = ind[i * 3 + 2];
				// Merge duplis
				for (f in faces) {
					if (vertices[a].equals(vertices[f.a])) a = f.a;
					else if (vertices[a].equals(vertices[f.b])) a = f.b;
					else if (vertices[a].equals(vertices[f.c])) a = f.c;
					if (vertices[b].equals(vertices[f.a])) b = f.a;
					else if (vertices[b].equals(vertices[f.b])) b = f.b;
					else if (vertices[b].equals(vertices[f.c])) b = f.c;
					if (vertices[c].equals(vertices[f.a])) c = f.a;
					else if (vertices[c].equals(vertices[f.b])) c = f.b;
					else if (vertices[c].equals(vertices[f.c])) c = f.c;
				}
				faces.push(new Face3(a, b, c));
			}
		}

		// Reorder vertices
		var verts = new Array<Vec4>();
		var map = new Map<Int, Int>();
		var i = 0;
		function orderVert(fi: Int): Int {
			var val = map.get(fi);
			if (val == null) {
				verts.push(vertices[fi]);
				map.set(fi, i);
				i++;
				return i - 1;
			}
			else return val;
		}
		for (f in faces) {
			f.a = orderVert(f.a);
			f.b = orderVert(f.b);
			f.c = orderVert(f.c);
		}

		var userData = new UserData();
		userData.mass = mass;
		userData.friction = friction;
		userData.velocity = velocity.clone();
		userData.angularVelocity = angularVelocity.clone();
		userData.breakable = breakable;
		userData.vertices = verts;
		userData.faces = faces;
		userDataMap.set(object, userData);
	}

	public function subdivideByPlane(object: MeshObject, plane: Vec4 = null, random: Bool = true): Array<MeshObject> {
		var debris: Array<MeshObject> = [];
		var scope = this;

		if (plane == null) plane = new Vec4(1, 1, 1);

		if (random)
			tempPlane2.normal.setFrom(new Vec4(
				plane.x > 0 ? Math.random() - 0.5 : plane.x,
				plane.y > 0 ? Math.random() - 0.5 : plane.y,
				plane.z > 0 ? Math.random() - 0.5 : plane.z
			).normalize());
		else
			tempPlane2.normal.setFrom(new Vec4(plane.x, plane.y, plane.z).normalize());

		tempPlane2.constant = -(object.transform.loc.dot(tempPlane2.normal));

		scope.cutByPlane(object, tempPlane2, scope.tempCutResult);

	    var object1 = scope.tempCutResult.object1;
	    var object2 = scope.tempCutResult.object2;

	    if (object1 != null) debris.push(object1);
	    if (object2 != null) debris.push(object2);

		iron.Scene.active.meshes.remove(object);

		return debris;		
	}

	// maxRadialIterations Iterations for radial cuts
	// maxRandomIterations Max random iterations for not-radial cuts
	public function subdivideByImpact(object: MeshObject, pointOfImpact: Vec4, normal: Vec4, maxRadialIterations: Int, maxRandomIterations: Int): Array<MeshObject> {
		var debris: Array<MeshObject> = [];

		tempVec4.addvecs(pointOfImpact, normal);
		tempPlane.setFromCoplanarPoints(pointOfImpact, object.transform.loc, tempVec4);

		var maxTotalIterations = maxRandomIterations + maxRadialIterations;
		var scope = this;

		function subdivideRadial(subObject: MeshObject, startAngle: Float, endAngle: Float, numIterations: Int) {

			if (Math.random() < numIterations * 0.05 || numIterations > maxTotalIterations) {
				debris.push(subObject);
				return;
			}

			var angle = Math.PI;
			if (numIterations == 0) {
				tempPlane2.normal.setFrom(tempPlane.normal);
				tempPlane2.constant = tempPlane.constant;
			}
			else {
				if (numIterations <= maxRadialIterations) {
					angle = (endAngle - startAngle) * (0.2 + 0.6 * Math.random()) + startAngle;

					// Rotate tempPlane2 at impact point around normal axis and the angle
					scope.tempVec42.setFrom(object.transform.loc).sub(pointOfImpact).applyAxisAngle(normal, angle).add(pointOfImpact);
					tempPlane2.setFromCoplanarPoints(pointOfImpact, scope.tempVec4, scope.tempVec42);
				}
				else {
					angle = ((0.5 * (numIterations & 1)) + 0.2 * (2 - Math.random())) * Math.PI;

					// Rotate tempPlane2 at object position around normal axis and the angle
					scope.tempVec42.setFrom(pointOfImpact).sub(subObject.transform.loc).applyAxisAngle(normal, angle).add(subObject.transform.loc);
					scope.tempVec43.setFrom(normal).add(subObject.transform.loc);
					tempPlane2.setFromCoplanarPoints(subObject.transform.loc, scope.tempVec43, scope.tempVec42);
				}
			}

			// Perform the cut
			scope.cutByPlane(subObject, tempPlane2, scope.tempCutResult);

			var object1 = scope.tempCutResult.object1;
			var object2 = scope.tempCutResult.object2;
			if (object1 != null) subdivideRadial(object1, startAngle, angle, numIterations + 1);
			if (object2 != null) subdivideRadial(object2, angle, endAngle, numIterations + 1);

			// Object was subdivided into debris
			iron.Scene.active.meshes.remove(subObject);
		}

		subdivideRadial(object, 0, 2 * Math.PI, 0);
		return debris;
	}

	function transformFreeVectorInverse(v: Vec4, m: Mat4): Vec4 {
		var x = v.x, y = v.y, z = v.z;
		v.x = m._00 * x + m._10 * y + m._20 * z;
		v.y = m._01 * x + m._11 * y + m._21 * z;
		v.z = m._02 * x + m._12 * y + m._22 * z;
		return v;
	}

	function transformTiedVectorInverse(v: Vec4, m: Mat4): Vec4 {
		var x = v.x - m._30, y = v.y - m._31, z = v.z - m._32;
		v.x = m._00 * x + m._10 * y + m._20 * z;
		v.y = m._01 * x + m._11 * y + m._21 * z;
		v.z = m._02 * x + m._12 * y + m._22 * z;
		return v;
	}

	function transformPlaneToLocalSpace(plane: Plane, m: Mat4, resultPlane: Plane) {
		var v1 = new Vec4();
		var referencePoint = transformTiedVectorInverse(plane.coplanarPoint(v1), m);
		resultPlane.normal.setFrom(plane.normal);
		transformFreeVectorInverse(resultPlane.normal, m);
		resultPlane.normal.normalize();
		resultPlane.constant = -referencePoint.dot(resultPlane.normal);
	}

	// Returns breakable objects, the resulting 2 pieces of the cut
	// object2 can be null if the plane doesn't cut the object
	// object1 can be null only in case of error
	// Returned value is number of pieces, 0 for error
	function cutByPlane(object: MeshObject, plane: Plane, output: CutResult): Int {
		var userData = userDataMap.get(object);
		var points: Array<Vec4> = userData.vertices;
		var faces: Array<Face3> = userData.faces;

		var numPoints = points.length;
		var points1 = [];
		var points2 = [];
		var delta = smallDelta;

		// Reset vertices mark
		for (i in 0...numPoints) points[i].w = 0;

		// Reset segments mark
		var numPointPairs = numPoints * numPoints;
		for (i in 0...numPointPairs) this.segments[i] = false;

		// Iterate through the faces to mark edges shared by coplanar faces
		for (i in 0...faces.length - 1) {
			var face1 = faces[i];

			for (j in (i + 1)...faces.length) {
				var face2 = faces[j];
				var coplanar = 1 - face1.normal.dot(face2.normal) < delta;

				if (coplanar) {
					var a1 = face1.a;
					var b1 = face1.b;
					var c1 = face1.c;
					var a2 = face2.a;
					var b2 = face2.b;
					var c2 = face2.c;

					if (a1 == a2 || a1 == b2 || a1 == c2) {
						if (b1 == a2 || b1 == b2 || b1 == c2) {
							this.segments[a1 * numPoints + b1] = true;
							this.segments[b1 * numPoints + a1] = true;
						}
						else {
							this.segments[c1 * numPoints + a1] = true;
							this.segments[a1 * numPoints + c1] = true;
						}
					}
					else if (b1 == a2 || b1 == b2 || b1 == c2) {
						this.segments[c1 * numPoints + b1] = true;
						this.segments[b1 * numPoints + c1] = true;
					}
				}
			}
		}

		// Transform the plane to object local space
		var localPlane = this.tempPlane;
		object.transform.buildMatrix();
		transformPlaneToLocalSpace(plane, object.transform.world, localPlane);

		// Iterate through the faces adding points to both pieces
		for (i in 0...faces.length) {

			var face = faces[i];
			for (segment in 0...3) {
				var i0 = segment == 0 ? face.a : (segment == 1 ? face.b : face.c);
				var i1 = segment == 0 ? face.b : (segment == 1 ? face.c : face.a);

				var segmentState = this.segments[i0 * numPoints + i1];
				// The segment already has been processed in another face
				if (segmentState) continue;

				// Mark segment as processed (also inverted segment)
				this.segments[i0 * numPoints + i1] = true;
				this.segments[i1 * numPoints + i0] = true;

				var p0 = points[i0];
				var p1 = points[i1];

				if (p0.w == 0) {
					var d = localPlane.distanceToPoint(p0);

					// mark: 1 for negative side, 2 for positive side, 3 for coplanar point
					if (d > delta) {
						p0.w = 2;
						points2.push(p0);
					}
					else if (d < -delta) {
						p0.w = 1;
						points1.push(p0);
					}
					else {
						p0.w = 3;
						points1.push(p0);
						var p02 = p0.clone();
						p02.w = 3;
						points2.push(p02);
					}
				}

				if (p1.w == 0) {
					var d = localPlane.distanceToPoint(p1);

					// mark: 1 for negative side, 2 for positive side, 3 for coplanar point
					if (d > delta) {
						p1.w = 2;
						points2.push(p1);
					}
					else if (d < -delta) {
						p1.w = 1;
						points1.push(p1);
					}
					else {
						p1.w = 3;
						points1.push(p1);
						var p1_2 = p1.clone();
						p1_2.w = 3;
						points2.push(p1_2);
					}
				}

				var mark0 = p0.w;
				var mark1 = p1.w;

				if ((mark0 == 1 && mark1 == 2 ) || ( mark0 == 2 && mark1 == 1)) {
					// Intersection of segment with the plane
					tempLine.start.setFrom(p0);
					tempLine.end.setFrom(p1);
					var intersection = localPlane.intersectLine(tempLine);
					if (intersection == null) return 0;

					intersection.w = 1;
					points1.push(intersection);
					var intersection_2 = intersection.clone();
					intersection_2.w = 2;
					points2.push(intersection_2);
				}
			}
		}

		// Calculate debris mass (very fast and precise):
		var newMass = userData.mass * 0.5;

		tempCM1.set(0, 0, 0);
		var radius1 = 0.0;
		if (points1.length > 0) {
			for (p in points1) 
				tempCM1.add(p);
			tempCM1.mult(1.0 / points1.length);
			for (p in points1) { 
				p.sub(tempCM1); radius1 = Math.max(radius1, p.length()); }
			tempCM1.applymat4(object.transform.world);
		}
		
		tempCM2.set(0, 0, 0);
		var radius2 = 0.0;
		if (points2.length > 0) {
			for (p in points2) 
				tempCM2.add(p);
			tempCM2.mult(1.0 / points2.length);
			for (p in points2) { 
				p.sub(tempCM2); radius2 = Math.max(radius2, p.length()); }
			tempCM2.applymat4(object.transform.world);
		}

		//MATERIALES
		var mats = object.materials;
		var udParent = userDataMap.get(object);
		if (udParent.matWeights == null) {
			udParent.matWeights = [];
			udParent.totalWeight = 0;
			for (i in 0...object.data.geom.indices.length) {
				var w = object.data.geom.indices[i].length;
				udParent.matWeights.push(w);
				udParent.totalWeight += w;
			}
		}

		function getWeightedIndex(): Int {
			var r = Std.random(udParent.totalWeight);
			var acc = 0;
			for (i in 0...udParent.matWeights.length) {
				acc += udParent.matWeights[i];
				if (r < acc) return i;
			}
			return 0;
		}

		var object1 = null;
		var object2 = null;
		var numObjects = 0;

		if (points1.length > 4) {
			var data1 = MeshDataExtension.makeMeshData(points1);
			if (data1 != null) {
				var sel1 = getWeightedIndex();
				var mats1 = [mats[sel1]];
				for (i in 0...mats.length) if (i != sel1) mats1.push(mats[i]);
				object1 = new MeshObject(data1, haxe.ds.Vector.fromArrayCopy(mats1));
				object1.transform.loc.setFrom(tempCM1);
				object1.transform.rot.setFrom(object.transform.rot);
				object1.transform.buildMatrix();
				initBreakableObject(object1, newMass, userData.friction, userData.velocity, userData.angularVelocity, 2 * radius1 > minSizeForBreak);
				userDataMap.get(object1).matWeights = udParent.matWeights;
				userDataMap.get(object1).totalWeight = udParent.totalWeight;
				numObjects++;
			}
		}

		if (points2.length > 4) {
			var data2 = MeshDataExtension.makeMeshData(points2);
			if (data2 != null) {
				var sel2 = getWeightedIndex();
				var mats2 = [mats[sel2]];
				for (i in 0...mats.length) if (i != sel2) mats2.push(mats[i]);
				object2 = new MeshObject(data2, haxe.ds.Vector.fromArrayCopy(mats2));
				object2.transform.loc.setFrom(tempCM2);
				object2.transform.rot.setFrom(object.transform.rot);
				object2.transform.buildMatrix();
				initBreakableObject(object2, newMass, userData.friction, userData.velocity, userData.angularVelocity, 2 * radius2 > minSizeForBreak);
				userDataMap.get(object2).matWeights = udParent.matWeights;
				userDataMap.get(object2).totalWeight = udParent.totalWeight;
				numObjects++;
			}
		}

		output.object1 = object1;
		output.object2 = object2;
		return numObjects;
	}
}

class UserData {

	public var mass: Float;
	public var friction: Float;
	public var velocity: Vec4;
	public var angularVelocity: Vec4;
	public var breakable: Bool;

	public var vertices: Array<Vec4>;
	public var faces: Array<Face3>;

	public var matWeights: Array<Int>;
	public var totalWeight: Int;

	public function new() {}
}

class CutResult {

	public var object1: MeshObject = null;
	public var object2: MeshObject = null;
	public function new() {}
}

class Line3 {

	public var start: Vec4;
	public var end: Vec4;

	public function new() {
		start = new Vec4();
		end = new Vec4();
	}

	public function delta(result: Vec4): Vec4 {
		result.subvecs(end, start);
		return result;
	}
}

class Plane {

	public var normal = new Vec4(1.0, 0.0, 0.0);
	public var constant = 0.0;

	public function new() {}

	public function distanceToPoint(point: Vec4): Float {
		return normal.dot(point) + constant;
	}

	public function setFromCoplanarPoints(a: Vec4, b: Vec4, c: Vec4): Plane {
		var v1 = new Vec4();
		var v2 = new Vec4();
		var normal = v1.subvecs(c, b).cross(v2.subvecs(a, b)).normalize();
		set(normal, a);
		return this;
	}

	public function set(normal: Vec4, point: Vec4): Plane {
		this.normal.setFrom(normal);
		constant = -point.dot(this.normal);
		return this;
	}

	public function coplanarPoint(result: Vec4): Vec4 {
		return result.setFrom(normal).mult(-constant);
	}

	public function intersectLine(line: Line3): Vec4 {
		var v1 = new Vec4();
		var result = new Vec4();
		var direction = line.delta(v1);
		var denominator = normal.dot(direction);
		if (denominator == 0) {
			// line is coplanar, return origin
			if (distanceToPoint(line.start) == 0) {
				return result.setFrom(line.start);
			}
			// Unsure if this is the correct method to handle this case.
			return null;
		}

		var t = -(line.start.dot(this.normal) + constant) / denominator;
		if (t < 0 || t > 1) return null;
		return result.setFrom(direction).mult(t).add(line.start);
	}
}