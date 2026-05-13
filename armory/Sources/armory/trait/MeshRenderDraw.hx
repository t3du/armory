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
	
	public function new() {
		super();
		notifyOnInit( () -> {

			RenderDraw.notifyOnRender( (draw:RenderDraw) -> {
				draw.strength = strength;
				draw.color = kha.Color.fromFloats(color.x, color.y, color.z, color.w);
				
				if (showBounds) draw.bounds(object.transform);
				if (showOutline) draw.outline(cast object);
				if (showWireframe) draw.wireframe(cast object);
			
			});
		});
	}
}