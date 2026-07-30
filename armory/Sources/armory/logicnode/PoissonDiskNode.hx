package armory.logicnode;

import armory.math.Generator;
import iron.math.Vec4;

class PoissonDiskNode extends LogicNode {

	public var property0: String;
	
	var points: Array<Vec4> = [];

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		switch(property0) {
			case 'Sample Cube':
				points = UniformPoissonSampler.SampleCube(inputs[3].get(), inputs[4].get(), inputs[2].get(), inputs[1].get());
			case 'Sample Sphere':
				points = UniformPoissonSampler.SampleSphere(inputs[3].get(), inputs[4].get(), inputs[2].get(), inputs[1].get());
			case 'Sample Rectangle':
				points = UniformPoissonSampler.SampleRectangle(inputs[3].get(), inputs[4].get(), inputs[2].get(), inputs[1].get());
			case 'Sample Circle':
				points = UniformPoissonSampler.SampleCircle(inputs[3].get(), inputs[4].get(), inputs[2].get(), inputs[1].get());
		}
		runOutput(0);
	}

	override function get(from: Int): Dynamic {
		return from == 1 ? points : points.length;
	}
}
