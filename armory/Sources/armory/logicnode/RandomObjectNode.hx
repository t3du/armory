package armory.logicnode;

import iron.Scene;
import iron.object.Object;
import iron.object.MeshObject;
import iron.data.MeshData;
import iron.data.MaterialData;
import iron.math.Mat4;
import iron.math.Vec4;
import armory.object.MeshDataExtension;

class RandomObjectNode extends LogicNode {

	var object: Object;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {

		var numPoints: Int = inputs[4].get();
		if (numPoints < 4) numPoints = 4;

		var mirrorX: Bool = inputs[5].get();
		var mirrorY: Bool = inputs[6].get();
		var mirrorZ: Bool = inputs[7].get();

		var md: MeshData = null;

		var m: Mat4 = inputs[2].get();
		var matrix: Mat4 = m != null ? m.clone() : null;

		var scale: Vec4 = matrix.getScale();

		var radiusX: Float = scale.x;
		var radiusY: Float = scale.y;
		var radiusZ: Float = scale.z;

		while (md == null){
			var points: Array<Vec4> = [];

			for (i in 0...numPoints) {
			    var x = (Math.random() - 0.5) * radiusX;
			    var y = (Math.random() - 0.5) * radiusY;
			    var z = (Math.random() - 0.5) * radiusZ;

			    points.push(new Vec4(x, y, z));

			    if (mirrorX)
			        points.push(new Vec4(-x, y, z));

			    if (mirrorY)
			        points.push(new Vec4(x, -y, z));
			    
			    if (mirrorZ)
			        points.push(new Vec4(x, y, -z));

			    if (mirrorX && mirrorY)
			        points.push(new Vec4(-x, -y, z));
			    
			    if (mirrorX && mirrorZ)
			        points.push(new Vec4(-x, y, -z));
			    
			    if (mirrorY && mirrorZ)
			        points.push(new Vec4(x, -y, -z));

			    if (mirrorX && mirrorY && mirrorZ)
			        points.push(new Vec4(-x, -y, -z));
			}
 
		md = MeshDataExtension.makeMeshData(points, inputs[8].get(), inputs[9].get());

		}	

		var material: MaterialData = inputs[3].get();
		var mat = new haxe.ds.Vector<MaterialData>(1);
		mat[0] = material;
		
		object = cast new MeshObject(md, mat);
		
		var name: String = inputs[1].get();
		object.name = name != "" ? name : md.name;
			
		var s = md.scalePos;
		var v = new kha.arrays.Float32Array(16);
		v[0] = s; v[5] = s; v[10] = s; v[15] = 1.0;

		var dims = new kha.arrays.Float32Array(3);
		dims[0] = md.geom.aabb.x;
		dims[1] = md.geom.aabb.y;
		dims[2] = md.geom.aabb.z;

		object.raw = { 
		    type: "mesh_object", 
		    name: object.name, 
		    data_ref: object.name, 
		    transform: { values: v },
		    dimensions: dims
		};

		object.setParent(Scene.active.root);
		object.addTrait(new armory.trait.internal.UniformsManager());
		
		if (matrix != null){
			object.transform.setMatrix(matrix);
			object.transform.scale.setFrom(new Vec4(1, 1, 1, 1));
			object.transform.buildMatrix();
		}

		runOutput(0);
	}

	override function get(from: Int): Dynamic {
		return object;
	}
}