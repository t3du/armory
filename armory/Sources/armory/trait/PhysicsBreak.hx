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
import armory.object.BreakerExtension;
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

	@prop
	var scaleUV: Float = 0.3;
	
	@prop
	var flatShading: Bool = true;

	public function new() {
		super();

		breaker = new ConvexBreaker(0.1);
		@:privateAccess breaker.scaleUV = scaleUV;
		@:privateAccess breaker.flatShading = flatShading;
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