package armory.logicnode;

import armory.renderpath.RenderToTexture;

class TranslateRenderTargetNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		RenderToTexture.ensure2DContext("TranslateRenderTargetNode");

		final x: Float = inputs[1].get();
		final y: Float = inputs[2].get();
		final revert: Bool = inputs[3].get();

		// Translate render target
		RenderToTexture.g.translate(x, y);

		// Execute all outputs
		runOutput(0);

		// Revert translation if enabled
		if (revert) RenderToTexture.g.translate(-x, -y);
	}
}
