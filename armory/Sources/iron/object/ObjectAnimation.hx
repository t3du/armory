package iron.object;

import iron.object.Animation.ActionSampler;

import kha.arrays.Float32Array;
import kha.FastFloat;
import kha.arrays.Uint32Array;
import iron.math.Vec4;
import iron.math.Mat4;
import iron.math.Quat;
import iron.data.SceneFormat;

class ObjectAnimation extends Animation {

	public var object: Object;
	public var oactions: Array<TSceneFormat>;
	var oaction: TObj;
	var s0: FastFloat = 0.0;
	var bezierFrameIndex = -1;

	var updateAnimation: Map<String, FastFloat> -> Void;

	public var transformArr: Float32Array;

	public var transformMap: Map<String, FastFloat>;

	public static var trackNames: Array<String> = [	"xloc", "yloc", "zloc",
											   		"xrot", "yrot", "zrot",
											   		"qwrot", "qxrot", "qyrot", "qzrot",
													"xscl", "yscl", "zscl",
													"dxloc", "dyloc", "dzloc",
													"dxrot", "dyrot", "dzrot",
													"dqwrot", "dqxrot", "dqyrot", "dqzrot",
													"dxscl", "dyscl", "dzscl"];

	public function new(object: Object, oactions: Array<TSceneFormat>) {
		this.object = object;
		this.oactions = oactions;
		isSkinned = false;
		super();
	}

	function getAction(action: String): TObj {
		for (a in oactions) if (a != null && a.objects[0].name == action) return a.objects[0];
		return null;
	}

	override public function play(action = "", onComplete: Void->Void = null, blendTime = 0.0, speed = 1.0, loop = true) {
		super.play(action, onComplete, blendTime, speed, loop);
		if (this.action == "" && oactions[0] != null) this.action = oactions[0].objects[0].name;
		oaction = getAction(this.action);
		if (oaction != null) {
			isSampled = oaction.sampled != null && oaction.sampled;
		}
	}

	override public function update(delta: FastFloat) {
		if (!object.visible || object.culled) return;

		#if arm_debug
		Animation.beginProfile();
		#end

		if(transformMap == null) transformMap = new Map();
		transformMap = initTransformMap();

		super.update(delta);
		if (paused) return;
		if(updateAnimation == null) return;
		if (!isSkinned) updateObjectAnimation();

		#if arm_debug
		Animation.endProfile();
		#end
	}

	public override function getTotalFrames(sampler: ActionSampler): Int {
		var track = getAction(sampler.action).anim.tracks[0];
		return Std.int(track.frames[track.frames.length - 1] - track.frames[0]);
	}

	public function initTransformMap(){

		var map = new Map<String, Null<FastFloat>>();
		for (name in trackNames){
			map.set(name, null);
		}

		return map;

	}

	public function animationLoop(f: Map<String, FastFloat>->Void){
		
		updateAnimation = f;
	}

	function updateObjectAnimation() {
		updateAnimation(transformMap);
		updateTransform(transformMap, object.transform);
		object.transform.buildMatrix();
	}

	override public function updateActionTrack(sampler: ActionSampler) {
		if(sampler.paused) return;

		if(! sampler.actionDataInit) {
			var objanim = getAction(sampler.action);
			sampler.setObjectAction(objanim);
		}

		oaction = sampler.getObjectAction();
		updateTrack(oaction.anim, sampler);

	}

	function updateAnimSampled(anim: TAnimation, transformMap: Map<String, FastFloat>, sampler: ActionSampler) {

		for (track in anim.tracks) {
			var sign = sampler.speed > 0 ? 1 : -1;

			var t = sampler.time;
			//t = t < 0 ? 0.1 : t;

			var ti = sampler.offset;
			//ti = ti < 0 ? 1 : ti;

			var t1 = track.frames[ti] * frameTime;
			var t2 = track.frames[ti + sign] * frameTime;
			var v1 = track.values[ti];
			var v2 = track.values[ti + sign];

			var value = interpolateLinear(t, t1, t2, v1, v2);

			if(value == null) continue;

			transformMap.set(track.target, value);
		}
	}

	public function sampleAction(sampler: ActionSampler, transformMap: Map<String, FastFloat>){

		if(! sampler.actionDataInit) {
			var objanim = getAction(sampler.action);
			sampler.setObjectAction(objanim);
		}

		var objanim = sampler.getObjectAction();
		updateAnimSampled(objanim.anim, transformMap, sampler);
	}

	public function blendActionObject(transformMap1: Map<String, FastFloat>, transformMap2: Map<String, FastFloat>, transformMapRes: Map<String, FastFloat>, factor: FastFloat ) {

		for(track in transformMapRes.keys()){

			var v1 = transformMap1.get(track);
			var v2 = transformMap2.get(track);

			if(v1 == null || v2 == null) continue;

			var maxVal: FastFloat = 1.0;
			var tempValue = (maxVal - factor) * v1 + factor * v2;
			transformMapRes.set(track, tempValue);
		}
		
	}

	inline function interpolateLinear(t: FastFloat, t1: FastFloat, t2: FastFloat, v1: FastFloat, v2: FastFloat): Null<FastFloat> {
		var s = (t - t1) / (t2 - t1);
		return (1.0 - s) * v1 + s * v2;
	}

	@:access(iron.object.Transform)
	function updateTransform(transformMap: Map<String, FastFloat>, transform: Transform) {

		var t = transform;
		t.resetDelta();

		for (track in transformMap.keys()){

			var value = transformMap.get(track);

			if(value == null) continue;

			switch (track) {

				case "xloc": transform.loc.x = value;
				case "yloc": transform.loc.y = value;
				case "zloc": transform.loc.z = value;
				case "xrot": transform.setRotation(value, transform._eulerY, transform._eulerZ);
				case "yrot": transform.setRotation(transform._eulerX, value, transform._eulerZ);
				case "zrot": transform.setRotation(transform._eulerX, transform._eulerY, value);
				case "qwrot": transform.rot.w = value;
				case "qxrot": transform.rot.x = value;
				case "qyrot": transform.rot.y = value;
				case "qzrot": transform.rot.z = value;
				case "xscl": transform.scale.x = value;
				case "yscl": transform.scale.y = value;
				case "zscl": transform.scale.z = value;
				// Delta
				case "dxloc": transform.dloc.x = value;
				case "dyloc": transform.dloc.y = value;
				case "dzloc": transform.dloc.z = value;
				case "dxrot": transform._deulerX = value;
				case "dyrot": transform._deulerY = value;
				case "dzrot": transform._deulerZ = value;
				case "dqwrot": transform.drot.w = value;
				case "dqxrot": transform.drot.x = value;
				case "dqyrot": transform.drot.y = value;
				case "dqzrot": transform.drot.z = value;
				case "dxscl": transform.dscale.x = value;
				case "dyscl": transform.dscale.y = value;
				case "dzscl": transform.dscale.z = value;
			}
		}		
	}
}
