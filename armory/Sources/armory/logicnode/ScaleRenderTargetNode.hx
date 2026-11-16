package armory.logicnode;

import armory.renderpath.RenderToTexture;
import kha.math.FastMatrix3;

class ScaleRenderTargetNode extends LogicNode {

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		RenderToTexture.ensure2DContext("ScaleRenderTargetNode");

		final sx: Float = inputs[1].get();
		final sy: Float = inputs[2].get();
		final centerX: Float = inputs[3].get();
		final centerY: Float = inputs[4].get();
		final revert: Bool = inputs[5].get();

		// Scale around (centerX, centerY)
		final mat = FastMatrix3.translation(centerX, centerY)
			.multmat(FastMatrix3.scale(sx, sy))
			.multmat(FastMatrix3.translation(-centerX, -centerY))
			.multmat(RenderToTexture.g.transformation);

		RenderToTexture.g.pushTransformation(mat);

		// Execute all outputs
		runOutput(0);

		// Revert scale if enabled
		if (revert) {
			RenderToTexture.g.popTransformation();
		}
	}
}
