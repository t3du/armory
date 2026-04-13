package iron.object;

import haxe.ds.Vector;
import iron.math.Vec3;
import iron.math.Vec2;
import kha.FastFloat;
import kha.arrays.Uint32Array;
import iron.math.Vec4;
import iron.math.Mat4;
import iron.math.Quat;
import iron.data.SceneFormat;

class Animation {

	public var isSkinned: Bool;
	public var isSampled: Bool;
	public var action = "";
	#if arm_skin
	public var armature: iron.data.Armature; // Bone
	#end

	// Helper variables.
	static var m1 = Mat4.identity();
	static var m2 = Mat4.identity();
	static var vpos = new Vec4();
	static var vpos2 = new Vec4();
	static var vscl = new Vec4();
	static var vscl2 = new Vec4();
	static var q1 = new Quat();
	static var q2 = new Quat();
	static var q3 = new Quat();
	static var vp = new Vec4();
	static var vs = new Vec4();

	public var time: FastFloat = 0.0;
	public var speed: FastFloat = 1.0;
	public var loop = true;
	public var frameIndex = 0;
	public var onComplete: Void->Void = null;
	public var paused = false;
	var frameTime: FastFloat = 1 / 60;

	var blendTime: FastFloat = 0.0;
	var blendCurrent: FastFloat = 0.0;
	var blendFactor: FastFloat = 0.0;

	var lastFrameIndex = -1;
	var markerEvents: Map<ActionSampler, Map<String, Array<Void->Void>>> = null;

	public var activeActions: Map<String, ActionSampler> = null;

	function new() {
		Scene.active.animations.push(this);
		if (Scene.active.raw.frame_time != null) {
			frameTime = Scene.active.raw.frame_time;
		}
		play();
	}

	public function play(action = "", onComplete: Void->Void = null, blendTime = 0.0, speed = 1.0, loop = true) {
		if (blendTime > 0) {
			this.blendTime = blendTime;
			this.blendCurrent = 0.0;
			frameIndex = 0;
			time = 0.0;
		}
		else frameIndex = -1;
		this.action = action;
		this.onComplete = onComplete;
		this.speed = speed;
		this.loop = loop;
		paused = false;
	}

	public function pause() {
		paused = true;
	}

	public function updateActionTrack(sampler: ActionSampler){
		return;
	}

	public function resume() {
		paused = false;
	}

	public function remove() {
		Scene.active.animations.remove(this);
	}

	public function update(delta: FastFloat) {
		if(activeActions == null) return;

		for(sampler in activeActions){
			if (sampler.paused || sampler.speed == 0.0) {
				continue;
			}
			else {
				sampler.timeOld = sampler.time;
				sampler.offsetOld = sampler.offset;
				sampler.setTimeOnly(sampler.time + delta * sampler.speed);
				updateActionTrack(sampler);
			}
		}
	}

	public function registerAction(actionID: String, sampler: ActionSampler){
		if (activeActions == null) activeActions = new Map();
		activeActions.set(actionID, sampler);
	}

	public function deRegisterAction(actionID: String) {
		if (activeActions == null) return;
		if(activeActions.exists(actionID)) activeActions.remove(actionID);

	}

	inline function isTrackEnd(track: TTrack, frameIndex: Int, speed: FastFloat): Bool {
		return speed > 0 ?
			frameIndex >= track.frames.length - 1 :
			frameIndex <= 0;
	}

	inline function checkFrameIndex(frameValues: Uint32Array, time: FastFloat, frameIndex: Int, speed: FastFloat): Bool {
		return speed > 0 ?
			((frameIndex + 1) < frameValues.length && time > frameValues[frameIndex + 1] * frameTime) :
			((frameIndex - 1) > -1 && time < frameValues[frameIndex - 1] * frameTime);
	}

	function rewind(track: TTrack) {
		frameIndex = speed > 0 ? 0 : track.frames.length - 1;
		time = track.frames[frameIndex] * frameTime;
	}

	function updateTrack(anim: TAnimation, sampler: ActionSampler) {

		var time = sampler.time;
		var frameIndex = sampler.offset;
		var speed = sampler.speed;
		sampler.cacheSet = false;
		sampler.trackEnd = false;

		var track = anim.tracks[0];

		if (frameIndex == -1) {
			sampler.timeOld = sampler.time;
			sampler.offsetOld = sampler.offset;
			frameIndex = speed > 0 ? 0 : track.frames.length - 1;
			time = track.frames[frameIndex] * frameTime;
		}

		// Move keyframe
		var sign = speed > 0 ? 1 : -1;
		while (checkFrameIndex(track.frames, time, frameIndex, speed)) frameIndex += sign;

		// Marker events
		if (markerEvents != null && anim.marker_names != null && frameIndex != lastFrameIndex) {
			if(markerEvents.get(sampler) != null){
				for (i in 0...anim.marker_frames.length) {
					if (frameIndex == anim.marker_frames[i]) {
						var marketAct = markerEvents.get(sampler);
						var ar = marketAct.get(anim.marker_names[i]);
						if (ar != null) for (f in ar) f();
					}
				}
				lastFrameIndex = frameIndex;
			}
		}

		// End of track
		if (isTrackEnd(track, frameIndex, speed)) {
			if (sampler.loop) {
				sampler.offsetOld = frameIndex;
				frameIndex = speed > 0 ? 0 : track.frames.length - 1;
				time = track.frames[frameIndex] * frameTime;
			}
			else {
				frameIndex -= sign;
				sampler.paused = true;
			}
			if (sampler.onComplete != null) for(func in sampler.onComplete){ func();};
			sampler.trackEnd = true;
		}

		sampler.setFrameOffsetOnly(frameIndex);
		sampler.speed = speed;
		sampler.setTimeOnly(time);

	}

	public function notifyOnMarker(sampler: ActionSampler, name: String, onMarker: Void->Void) {
		if (markerEvents == null) markerEvents = new Map();
		
		var markerAct = markerEvents.get(sampler);
		if(markerAct == null){
			markerAct = new Map();
			markerEvents.set(sampler, markerAct);
		}

		var ar = markerAct.get(name);
		if (ar == null) {
			ar = [];
			markerAct.set(name, ar);
		}
		ar.push(onMarker);
	}

	public function removeMarker(sampler: ActionSampler, name: String, onMarker: Void->Void) {
		var markerAct = markerEvents.get(sampler);
		if(markerAct == null) return;

		markerAct.get(name).remove(onMarker);
	}

	public function currentFrame(): Int {
		return Std.int(time / frameTime);
	}

	public function getTotalFrames(sampler: ActionSampler): Int {
		return 0;
	}

	#if arm_debug
	public static var animationTime = 0.0;
	static var startTime = 0.0;

	static function beginProfile() {
		startTime = kha.Scheduler.realTime();
	}
	static function endProfile() {
		animationTime += kha.Scheduler.realTime() - startTime;
	}
	public static function endFrame() {
		animationTime = 0;
	}
	#end
}

/**
 * Action Sampler State.
 */
class ActionSampler {

	/**
	 * Name of the action.
	 */
	public var action(default, null): String;
	/**
	 * Current time of the sampler.
	 */
	public var time(default, null): FastFloat = 0.0;
	/**
	 * Current frame of the sampler.
	 */
	public var offset(default, null): Int = 0;
	/**
	 * Total frames in the action.
	 */
	public var totalFrames: Null<Int> = null;
	/**
	 * Speed of action sampling.
	 */
	public var speed: FastFloat;
	/**
	 * Loop action.
	 */
	public var loop: Bool;
	/**
	 * Sampler paused.
	 */
	public var paused: Bool = false;
	/**
	 * Callback functions to call after action ends.
	 */
	public var onComplete: Array<Void -> Void>;
	/**
	 * Action track ended.
	 */
	public var trackEnd: Bool = false;
	public var timeOld: FastFloat = 0.0;
	public var offsetOld: Int = 0;
	/**
	 * Cache action data objects. May be Bones or Objects.
	 */
	var actionData: Array<TObj> = null;
	/**
	 * Action data has been cached.
	 */
	public var actionDataInit(default, null): Bool = false;
	/**
	 * Positional Root Motion for this action.
	 */
	public var rootMotionPos: Bool = false;
	/**
	 * Rotational Root Motion for this action.
	 */
	public var rootMotionRot: Bool = false;
	/**
	 * Action matrix from previous sample. Mainly used for root motion.
	 */
	var actionCache: Mat4 = Mat4.identity();
	/**
	 * `actionCache` set this frame.
	 */
	public var cacheSet: Bool = false;
	/**
	 * `actionCache` initialized. Set to false to force reset cache.
	 */
	public var cacheInit(default, null): Bool = false;

	/**
	 * Create a new action sampler.
	 * @param action Name of the action.
	 * @param speed Speed of sampler.
	 * @param loop Loop after action ends.
	 * @param startPaused Do not start sample on init.
	 * @param onComplete Callback functions after action completes.
	 */
	public inline function new(action: String, speed: FastFloat = 1.0, loop: Bool = true, startPaused: Bool = false, onComplete: Array<Void -> Void> = null) {
		this.action = action;
		this.speed = speed;
		this.loop = loop;
		this.onComplete = onComplete;
		this.paused = startPaused;
	}

	/**
	 * Set current frame of the sampler. Time is calculated.
	 * @param frameOffset Frame.
	 */
	public inline function setFrameOffset(frameOffset: Int){
		this.offset = frameOffset;
		this.time = Scene.active.raw.frame_time * offset;
		cacheInit = false;
	}

	/**
	 * Set current time of the sampler. Frame is calculated.
	 * @param timeOffset Time.
	 */
	public inline function setTimeOffset(timeOffset: FastFloat){
		this.time = timeOffset;
		var ftime: FastFloat = Scene.active.raw.frame_time;
		this.offset = Std.int(time / ftime);
		cacheInit = false;
	}

	/**
	 * Restart action.
	 */
	public inline function restartAction() {
		this.setFrameOffset(0);
		paused = false;
		cacheInit = false;
	}

	/**
	 * Add a callback function when action completes.
	 * @param onComplete Callback
	 */
	public function notifyOnComplete(onComplete: Void -> Void) {
		if(this.onComplete == null) this.onComplete = [];
		this.onComplete.push(onComplete);
	}

	/**
	 * Remove callback function
	 * @param onComplete Callback
	 */
	public function removeOnComplete(onComplete: Void -> Void) {
		this.onComplete.remove(onComplete);
	}

	/**
	 * Set time offset only. Frame will not be set.
	 * @param time Time.
	 */
	public inline function setTimeOnly(time: FastFloat) {
		this.time = time;
	}

	/**
	 * Set frame offset only. Time will not be set.
	 * @param frame Frame
	 */
	public inline function setFrameOffsetOnly(frame: Int) {
		this.offset = frame;
	}

	/**
	 * Get raw bones data for bone animation.
	 * @return Null<Array<TObj>> Raw bone action data.
	 */
	public inline function getBoneAction(): Null<Array<TObj>> {
		return actionData;
	}

	/**
	 * Get raw object data for object animation.
	 * @return Null<TObj> Raw object action data.
	 */
	public inline function getObjectAction(): Null<TObj> {
		if(actionData != null) return actionData[0];
		return null;
	}

	/**
	 * Cache raw bones data for bone animation.
	 * @param actionData Raw bone data.
	 */
	public inline function setBoneAction(actionData: Array<TObj>) {
		this.actionData = actionData;
		this.totalFrames = actionData[0].anim.tracks[0].frames.length;
		if(actionData[0].anim.root_motion_pos) this.rootMotionPos = true;
		if(actionData[0].anim.root_motion_rot) this.rootMotionRot = true;
		actionDataInit = true;
	}

	/**
	 * Cache raw object data for object animation.
	 * @param actionData Raw object data.
	 */
	public inline function setObjectAction(actionData: TObj) {
		this.actionData = [actionData];
		this.totalFrames = actionData.anim.tracks[0].frames.length;
		actionDataInit = true;
	}

	/**
	 * Temporary cache of action matrix from previous frame.
	 * @param m Matrix to cache.
	 */
	public inline function setActionCache(m: Mat4) {
		if(! cacheSet) actionCache.setFrom(m);
		cacheSet = true;
		cacheInit = true;
	}

	/**
	 * Copy cahced action matrix and to the matrix.
	 * @param m Matrix to copy the cache to.
	 */
	public inline function getActionCache(m: Mat4) {
		m.setFrom(actionCache);
	}
}
