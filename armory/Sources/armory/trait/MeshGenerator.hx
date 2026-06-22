package armory.trait;

import iron.Trait;
import iron.math.Vec4;
import iron.object.Object;
import iron.object.MeshObject;
import iron.object.Transform;
import iron.Scene;
import iron.data.SceneFormat;
import iron.data.Data;
import iron.data.MeshData;
import iron.data.MaterialData;

import armory.object.MeshDataExtension;

class MeshGenerator extends Trait {

	@prop
	var numPoints: Int = 5;

	@prop
	var radius: Float = 5.0;

	@prop
	var mirrorX: Bool = false;

	@prop
	var mirrorY: Bool = false;

	@prop
	var mirrorZ: Bool = false;

	@prop
	var material: String = '';

	@prop
	var scaleUV: Float = 0.3;

	@prop
	var loc: Vec4 = new Vec4(0, 0, 0);

	@prop
	var rot: Vec4 = new Vec4(0, 0, 0);

	@prop
	var traitName: String = '';

	public function new() {
		super();
		notifyOnInit(init);
	}

	function init() {

		if (numPoints < 4) numPoints = 4;
		if (radius < 0.1) radius = 0.1;

		var md: MeshData = null;

		while (md == null){
			var points: Array<Vec4> = [];

			for (i in 0...numPoints) {
			    var x = (Math.random() - 0.5) * radius;
			    var y = (Math.random() - 0.5) * radius;
			    var z = (Math.random() - 0.5) * radius;

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
 
		md = MeshDataExtension.makeMeshData(points, scaleUV);

		}

		/*safe mesh
		// Plane
		points = [
		    new Vec4(-1.0, 0.0, -1.0), //
		    new Vec4( 1.0, 0.0, -1.0), //
		    new Vec4( 1.0, 0.0,  1.0), //
		    new Vec4(-1.0, 0.0,  1.0)  //
		];

		if (md == null) {
	        points = [
	            new Vec4(-0.5, -0.5, -0.5), new Vec4(0.5, -0.5, -0.5),
	            new Vec4(0.5, 0.5, -0.5), new Vec4(-0.5, 0.5, -0.5),
	            new Vec4(-0.5, -0.5, 0.5), new Vec4(0.5, -0.5, 0.5),
	            new Vec4(0.5, 0.5, 0.5), new Vec4(-0.5, 0.5, 0.5)
	        ];

	        for (p in points) {
	            p.x *= radius;
	            p.y *= radius;
	            p.z *= radius;

	            var offset = radius * 0.1;
	            p.x += (Math.random() - 0.5) * offset;
	            p.y += (Math.random() - 0.5) * offset;
	            p.z += (Math.random() - 0.5) * offset;
	        }

	        md = MeshDataExtension.makeMeshData(points);
		}
		*/

		var mat = new haxe.ds.Vector<MaterialData>(1);

		if (material != '')
			Data.getMaterial(Scene.active.raw.name, material, function(data:MaterialData) {
				mat[0] = data != null ? data : Scene.active.meshes[0].materials[0];	
			});
		 else
		    mat[0] = Scene.active.meshes[0].materials[0];	

		var obj: Object = cast new MeshObject(md, mat);
		obj.name = md.name;
			
		var s = md.scalePos;
		var v = new kha.arrays.Float32Array(16);
		v[0] = s; v[5] = s; v[10] = s; v[15] = 1.0;

		var dims = new kha.arrays.Float32Array(3);
		dims[0] = md.geom.aabb.x;
		dims[1] = md.geom.aabb.y;
		dims[2] = md.geom.aabb.z;

		obj.raw = { 
		    type: "mesh_object", 
		    name: md.name, 
		    data_ref: md.name, 
		    transform: { values: v },
		    dimensions: dims
		};

		obj.setParent(Scene.active.root);
		obj.transform.loc.setFrom(loc);
		var degToRad = Math.PI / 180;
		obj.transform.setRotation(rot.x * degToRad, rot.y * degToRad, rot.z * degToRad);
		obj.transform.buildMatrix();
		//obj.addTrait(new armory.trait.physics.RigidBody());
		obj.addTrait(new armory.trait.internal.UniformsManager());
		if (traitName != ''){
			var cname = Type.resolveClass(Main.projectPackage + "." + traitName);
			if (cname == null) cname = Type.resolveClass(Main.projectPackage + ".node." + traitName);
			var trait = Type.createInstance(cname, []);
			obj.addTrait(trait);
		}

	}

}