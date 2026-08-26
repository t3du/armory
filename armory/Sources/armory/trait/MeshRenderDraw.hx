package armory.trait;

import armory.trait.internal.RenderDraw;
import iron.math.Vec4;

class MeshRenderDraw extends iron.Trait {

	@prop
	public var strength:Float = 0.1;

	@prop
	public var color:Vec4 = new Vec4(0, 0, 0, 1);

	@prop
	public var showBounds:Bool = true;

	@prop
	public var showWireframe:Bool = false;

	@prop
	public var showOutline:Bool = false;

	@prop
	public var active:Bool = true;

	var renderCb: kha.graphics4.Graphics->Int->Int->Void = null;

	public function new() {
		super();
		notifyOnInit(function() {
			renderCb = RenderDraw.notifyOnRender( (draw:RenderDraw) -> {
				if (!active) return;
				draw.strength = strength;
				draw.color = kha.Color.fromFloats(color.x, color.y, color.z, color.w);

				if (showBounds) draw.bounds(object.transform);
				if (showOutline) draw.outline(cast object);
				if (showWireframe) draw.wireframe(cast object);

			});
		});
	}

	override public function remove() {
		active = false;
		if (renderCb != null) {
			RenderDraw.removeOnRender(renderCb);
			renderCb = null;
		}
		super.remove();
	}
}