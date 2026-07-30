package armory.logicnode;

import armory.math.Generator;
import iron.math.Vec4;

class ProceduralNoiseNode extends LogicNode {

	public var property0: String;
	
	var value: Float;
	var p: Perlin = null;
	var ds: DiamondSquare = null;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		if (property0 == 'Perlin' || property0 == 'Octave Perlin'){
			if (p == null)
				p = new Perlin(inputs[4].get());
			if (property0 == 'Perlin')
				value = p.perlin(inputs[1].get(), inputs[2].get(), inputs[3].get());
			else
				value = p.octavePerlin(inputs[1].get(), inputs[2].get(), inputs[3].get(), inputs[5].get(), inputs[6].get(), inputs[7].get());
		} else {
			if (ds == null){
				var width: Int = inputs[3].get();
				var height: Int = inputs[4].get();
				var featureSize: Int = inputs[5].get();

				width = Std.int(Math.pow(2, Math.ceil(Math.log(width - 1) / Math.log(2)))) + 1;
				height = Std.int(Math.pow(2, Math.ceil(Math.log(height - 1) / Math.log(2)))) + 1;
				featureSize = Std.int(Math.pow(2, Math.floor(Math.log(featureSize) / Math.log(2))));
				
				ds = new DiamondSquare(width, height, featureSize, inputs[6].get(), function(){ return Math.random() - inputs[7].get();});
				ds.diamondSquare();
			}
			value = ds.getValue(inputs[1].get(), inputs[2].get());
		}
			
		runOutput(0);
	}

	override function get(from: Int): Dynamic {
		return value;
	}
}
