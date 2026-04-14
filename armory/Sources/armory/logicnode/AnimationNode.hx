package armory.logicnode;

import iron.object.Object;
import iron.object.Animation;
import iron.object.ObjectAnimation;

class AnimationNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}
	
	override function get(from: Int): Dynamic {
		var object: Object = inputs[0].get();

		if (object == null) 
			return from == 0 ? null : 0;

		var animation: Animation = object.animation;
		if (animation == null) animation = object.getBoneAnimation(object.uid);

		var actions: Array<String> = [];

		if (animation.isSkinned)
			for(a in animation.armature.actions)
				actions.push(a.name);
		else
			for (a in cast(animation, ObjectAnimation).oactions)
				if (a != null)
					actions.push(a.objects[0].name);

		return from == 0 ? actions : actions.length;

	}
}
