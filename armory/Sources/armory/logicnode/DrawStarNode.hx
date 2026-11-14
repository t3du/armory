package armory.logicnode;

import kha.Color;
import kha.math.Vector2;
import armory.renderpath.RenderToTexture;

#if arm_ui
using zui.GraphicsExtension;
#end

class DrawStarNode extends LogicNode {
	public function new(tree: LogicTree) super(tree);

	override function run(from: Int) {
		#if arm_ui
		RenderToTexture.ensure2DContext("DrawStarNode");
		final n = Std.int(Math.max(3, inputs[4].get()));
		final x = inputs[5].get();
		final y = inputs[6].get();
		final outer = inputs[7].get();
		final inner = inputs[8].get();
		final angle = inputs[9].get();
		final v = new Array<Vector2>();

		for (i in 0...(n * 2)) {
			final a = -Math.PI / 2 + i * Math.PI / n;
			final r = i % 2 == 0 ? outer : inner;
			v.push(new Vector2(Math.cos(a) * r, Math.sin(a) * r));
		}

		final c = inputs[1].get();
		RenderToTexture.g.rotate(angle, x, y);
		RenderToTexture.g.color = Color.fromFloats(c.x, c.y, c.z, c.w);

		if (inputs[2].get()) {
			for (i in 0...(n * 2)) {
				final a = v[i];
				final b = v[(i + 1) % (n * 2)];
				RenderToTexture.g.fillTriangle(x, y, a.x + x, a.y + y, b.x + x, b.y + y);
			}
		}
		else RenderToTexture.g.drawPolygon(x, y, v, inputs[3].get());

		RenderToTexture.g.rotate(-angle, x, y);
		#end
		runOutput(0);
	}
}