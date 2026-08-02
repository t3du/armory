package armory.logicnode;

import iron.object.Object;

#if arm_physics
import armory.trait.physics.RigidBody;
import armory.trait.physics.RigidBody.Shape;
#end


class AddRigidBodyNode extends LogicNode {

	public var property0: String; //Shape
	public var property1: Bool; //Advanced
	public var object: Object;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		object = inputs[1].get();

#if arm_physics

		var mass: Float = inputs[2].get();
		var active: Bool = inputs[3].get();
		var animated: Bool = inputs[4].get();
		var trigger: Bool = inputs[5].get();
		var friction: Float = inputs[6].get();
		var bounciness: Float = inputs[7].get();
		var ccd: Bool = inputs[8].get();

		var margin: Bool = false;
		var marginLen: Float = 0.0;
		var linDamp: Float = 0.0;
		var angDamp: Float = 0.0;
		var angFriction: Float = 0.0;
		var useDeactiv: Bool = false;
		var linearVelThreshold: Float = 0.0;
		var angVelThreshold: Float = 0.0;
		var group: Int = 1;
		var mask: Int = 1;

		var shape: Shape = 1;

		if (property1) {
			margin = inputs[9].get();
			marginLen = inputs[10].get();
			linDamp = inputs[11].get();
			angDamp = inputs[12].get();
			angFriction = inputs[13].get();
			useDeactiv = inputs[14].get();
			linearVelThreshold = inputs[15].get();
			angVelThreshold = inputs[16].get();
			group = inputs[17].get();
			mask = inputs[18].get();
		}

		var rb: RigidBody = object.getTrait(RigidBody);
		if ((group < 0) || (group > 32)) group = 1; //Limiting max groups to 32
		if ((mask < 0) || (mask > 32)) mask = 1; //Limiting max masks to 32
		if (rb == null) {
			switch (property0) {
				case "Box": shape = Box;
				case "Sphere": shape = Sphere;
				case "Capsule": shape = Capsule;
				case "Cone": shape = Cone;
				case "Cylinder": shape = Cylinder;
				case "Convex Hull": shape = ConvexHull;
				case "Mesh": shape = Mesh;
				case "Compound Parent": shape = Compound;
			}

			rb = new RigidBody(shape, mass, friction, bounciness, group, mask);
			rb.animated = animated;
			rb.staticObj = !active;
			rb.isTriggerObject(trigger);

			if (property0 == "Compound Parent") {
				var compoundChildren = [];
				for (child in object.children) {
					var childRb: RigidBody = child.getTrait(RigidBody);
					if (childRb != null) {
						var childShape = 0;
						switch (@:privateAccess childRb.shape) {
							case Box: childShape = 0;
							case Sphere: childShape = 1;
							case ConvexHull: childShape = 2;
							case Mesh: childShape = 3;
							case Cone: childShape = 4;
							case Cylinder: childShape = 5;
							case Capsule: childShape = 6;
							default: childShape = 0;
						}
						childRb.remove();
						var m = object.transform.world.clone();
						m.getInverse(object.transform.world);
						m.multmat(child.transform.world);
						var loc = new iron.math.Vec4();
						var rot = new iron.math.Quat();
						var scl = new iron.math.Vec4();
						m.decompose(loc, rot, scl);
						compoundChildren.push({
							shape: childShape,
							posX: loc.x,
							posY: loc.y,
							posZ: loc.z,
							rotX: rot.x,
							rotY: rot.y,
							rotZ: rot.z,
							rotW: rot.w,
							dimX: child.transform.dim.x,
							dimY: child.transform.dim.y,
							dimZ: child.transform.dim.z
						});
					}
				}
				@:privateAccess rb.compoundChildren = compoundChildren;
			}

			if (property1) {
				rb.linearDamping = linDamp;
				rb.angularDamping = angDamp;
				rb.angularFriction = angFriction;
				if (margin) rb.collisionMargin = marginLen;
				if (useDeactiv) {
					rb.setUpDeactivation(true, linearVelThreshold, angVelThreshold, 0.0);
				}
			}

			object.addTrait(rb);
		}
#end

		runOutput(0);
	}

	override function get(from: Int): Object {
		return object;
	}
}
