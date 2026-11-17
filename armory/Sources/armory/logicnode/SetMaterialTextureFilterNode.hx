package armory.logicnode;

import iron.object.MeshObject;
import iron.data.MaterialData;

class SetMaterialTextureFilterNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var object: MeshObject = inputs[1].get();
		var mat: MaterialData = inputs[2].get();
		var name: String = inputs[3].get();
		var filter: Int = inputs[4].get();

		if (object == null || mat == null){ runOutput(0); return; }

		for (i => node in mat.contexts[0].raw.bind_textures)
			if (node.name == name){
				var imgt = mat.contexts[0].raw.bind_textures[i];
				switch(filter){
					case 0: //Linear
						imgt.min_filter = null;
						imgt.mag_filter = null;
						imgt.mipmap_filter = null;
						imgt.generate_mipmaps = null;
					case 1: //Closest
						imgt.min_filter = 'point';
						imgt.mag_filter = 'point';
						imgt.mipmap_filter = null;
						imgt.generate_mipmaps = null;
					case 2: //Cubic
						imgt.min_filter = null;
						imgt.mag_filter = null;
						imgt.mipmap_filter = 'linear';
						imgt.generate_mipmaps = true;
					case 3: //Smart
						imgt.min_filter = 'anisotropic';
						imgt.mag_filter = null;
						imgt.mipmap_filter = 'linear';
						imgt.generate_mipmaps = true;
				}

				break;
			}

		runOutput(0);
	}
}