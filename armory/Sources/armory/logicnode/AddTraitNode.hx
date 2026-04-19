package armory.logicnode;

import iron.object.Object;

class AddTraitNode extends LogicNode {

	public var property0: String;
	var trait: Dynamic;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var object: Object = inputs[1].get();
		assert(Error, object != null, "Object should not be null");

		if (property0 == 'TraitName'){
			var traitName: String = inputs[2].get();

			assert(Error, traitName != null, "Trait name should not be null");

			var cname = Type.resolveClass(Main.projectPackage + "." + traitName);
			if (cname == null) cname = Type.resolveClass(Main.projectPackage + ".node." + traitName);
			assert(Error, cname != null, 'No trait with the name "$traitName" found, make sure that the trait is exported!');
			assert(Warning, object.getTrait(cname) == null, 'Object already has the trait "$traitName" applied');

			trait = Type.createInstance(cname, []);

		} else
			trait = inputs[2].get();		

		object.addTrait(trait);

		runOutput(0);
	}

	override function get(from: Int): Dynamic {
		return trait;
	}
}
