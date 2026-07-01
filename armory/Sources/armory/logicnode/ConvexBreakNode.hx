package armory.logicnode;

import iron.object.Object;
import iron.object.MeshObject;
import armory.object.BreakerExtension;
import iron.math.Vec4;

class ConvexBreakNode extends LogicNode {

	public var property0: String;

	var objects: Array<Object>;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		objects = [];
		var object: Object = inputs[1].get();

		var breaker: ConvexBreaker = new ConvexBreaker(0.1);
		@:privateAccess breaker.scaleUV = inputs[3].get();
		@:privateAccess breaker.flatShading = inputs[4].get();

		breaker.initBreakableObject(cast object, 0, 0, new Vec4(), new Vec4(), true);

		var debris: Array<MeshObject> = [];

		if (property0 == 'Plane')
			debris = breaker.subdivideByPlane(cast object, inputs[3].get(), inputs[2].get());
		else
			debris = breaker.subdivideByImpact(cast object, inputs[2].get(), inputs[3].get(), 1, 1);

		for (o in debris) {
			var obj: Object = cast o;
			obj.name = o.data.raw.name;
			
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

			obj.addTrait(new armory.trait.internal.UniformsManager());

			var ud = breaker.userDataMap.get(cast o);
			if (ud == null) continue;
			objects.push(obj);
		}

		if (objects.length > 1){
			for (obj in objects)
				obj.setParent(iron.Scene.active.root);
			object.remove();
			runOutput(1);
			}
		else 
			runOutput(2);
		
		runOutput(0);
	}

	override function get(from: Int): Dynamic {
		return objects;
	}
}