
package armory.logicnode;

import iron.math.Vec4;
import armory.trait.internal.Spectral;

class ComplementaryColorNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var color:Vec4 = inputs[0].get();
		return from == 0 ? Spectral.complementaryRGB(color) : Spectral.complementaryRYB(color);
	}
}