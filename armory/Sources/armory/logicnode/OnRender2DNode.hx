package armory.logicnode;

import iron.App;
import armory.renderpath.RenderToTexture;

class OnRender2DNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
		#if arm_ui
		tree.notifyOnInit(initNode);
		#end
	}

	function initNode() {
		tree.notifyOnRender2D(onRender2D, inputs[0].get());
	}

	function onRender2D(g: kha.graphics2.Graphics) {
		RenderToTexture.ensureEmptyRenderTarget("OnRender2DNode");
		RenderToTexture.g = g;
		runOutput(0);
		RenderToTexture.g = null;
	}

	override function get(from: Int): Dynamic { 
		return from == 1 ? onRender2D : @:privateAccess App.traitRenders2D.indexOf(onRender2D);
	}
}
