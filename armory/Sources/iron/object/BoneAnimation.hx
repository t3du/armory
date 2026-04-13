package iron.object;

import iron.object.Animation.ActionSampler;
#if arm_skin

import kha.FastFloat;
import kha.arrays.Float32Array;
import iron.math.Vec4;
import iron.math.Mat4;
import iron.math.Quat;
import iron.data.MeshData;
import iron.data.SceneFormat;
import iron.data.Armature;
import iron.data.Data;
import iron.math.Ray;

class BoneAnimation extends Animation {

	public static var skinMaxBones = 128;

	// Skinning
	public var object: MeshObject;
	public var armatureObject: Object;
	public var data: MeshData;
	public var skinBuffer: Float32Array;

	var updateAnimation: Array<Mat4>->Void = null;

	public var skeletonBones(default, null): Array<TObj> = null;
	public var skeletonMats(default, null): Array<Mat4> = null;
	//var skeletonBonesBlend: Array<TObj> = null;
	var absMats: Array<Mat4> = null;
	var applyParent: Array<Bool> = null;
	var matsFast: Array<Mat4> = [];
	var matsFastSort: Array<Int> = [];
	var matsFastBlend: Array<Mat4> = [];
	var matsFastBlendSort: Array<Int> = [];

	var rootMotionCacheInit: Bool = false;
	public var rootMotion(default, null): TObj = null;
	public var rootMotionVelocity(default, null): Vec4 = null;
	public var rootMotionRotation(default, null): Quat = null;
	var rootMotionIndex: Int = -1;
	var rootMotionLockX: Bool = false;
	var rootMotionLockY: Bool = false;
	var rootMotionLockZ: Bool = false;

	var delta: FastFloat = 0;

	var boneChildren: Map<String, Array<Object>> = null; // Parented to bone

	var constraintTargets: Array<Object> = null;
	var constraintTargetsI: Array<Mat4> = null;
	var constraintMats: Map<TObj, Mat4> = null;
	var relativeBoneConstraints: Bool = false;

	static var m = Mat4.identity(); // Skinning matrix
	static var m1 = Mat4.identity();
	static var m2 = Mat4.identity();
	static var bm = Mat4.identity(); // Absolute bone matrix
	static var wm = Mat4.identity();
	static var vpos = new Vec4();
	static var vpos2 = new Vec4();
	static var vpos3 = new Vec4();
	static var vscl = new Vec4();
	static var vscl2 = new Vec4();
	static var vscl3 = new Vec4();
	static var q1 = new Quat();
	static var q2 = new Quat();
	static var q3 = new Quat();
	static var q4 = new Quat();
	static var v1 = new Vec4();
	static var v2 = new Vec4();

	public function new(armatureUid: Int, armatureObject: Object) {
		super();
		this.isSampled = false;
		this.armatureObject = armatureObject;
		for (a in Scene.active.armatures) {
			if (a.uid == armatureUid) {
				this.armature = a;
				break;
			}
		}
	}

	public function initMatsEmpty(): Array<Mat4> {

		var mats = [];
		for(i in 0...skeletonMats.length) mats.push(Mat4.identity());
		return mats;
	}
	
	public inline function getNumBones(): Int {
		if (skeletonBones == null) return 0;
		return skeletonBones.length;
	}

	public function setSkin(mo: MeshObject) {
		this.object = mo;
		this.data = mo != null ? mo.data : null;
		this.isSkinned = data != null ? data.isSkinned : false;
		if (this.isSkinned) {
			var boneSize = 12; // Dual-quat skinning + scaling
			this.skinBuffer = new Float32Array(skinMaxBones * boneSize);
			for (i in 0...this.skinBuffer.length) this.skinBuffer[i] = 0;
			// Rotation is already applied to skin at export
			object.transform.rot.set(0, 0, 0, 1);
			object.transform.buildMatrix();

			var refs = mo.parent.raw.bone_actions;
			if (refs != null && refs.length > 0) {
				Data.getSceneRaw(refs[0], function(action: TSceneFormat) { play(action.name); });
			}
		}
		if (armatureObject.raw.relative_bone_constraints) relativeBoneConstraints = true;

	}

	public function addBoneChild(bone: String, o: Object) {
		if (boneChildren == null) boneChildren = new Map();
		var ar = boneChildren.get(bone);
		if (ar == null) {
			ar = [];
			boneChildren.set(bone, ar);
		}
		ar.push(o);
	}
	
	public function removeBoneChild(bone: String, o: Object) {
		if (boneChildren != null) {
			var ar = boneChildren.get(bone);
			if (ar != null) ar.remove(o);
		}
	}
 
	@:access(iron.object.Transform)
	function updateBoneChildren(bone: TObj, bm: Mat4) {
		var ar = boneChildren.get(bone.name);
		if (ar == null) return;
		for (o in ar) {
			var t = o.transform;
			if (t.boneParent == null) t.boneParent = Mat4.identity();
			if (o.raw.parent_bone_tail != null) {
				if (o.raw.parent_bone_connected || isSkinned) {
					var v = o.raw.parent_bone_tail;
					t.boneParent.initTranslate(v[0], v[1], v[2]);
					t.boneParent.multmat(bm);
				}
				else {
					var v = o.raw.parent_bone_tail_pose;
					t.boneParent.setFrom(bm);
					t.boneParent.translate(v[0], v[1], v[2]);
				}
			}
			else t.boneParent.setFrom(bm);
			t.buildMatrix();
		}
	}

	function numParents(b: TObj): Int {
		var i = 0;
		var p = b.parent;
		while (p != null) {
			i++;
			p = p.parent;
		}
		return i;
	}

	function setMats() {
		while (matsFast.length < skeletonBones.length) {
			matsFast.push(Mat4.identity());
			matsFastSort.push(matsFastSort.length);
		}
		// Calc bones with 0 parents first
		matsFastSort.sort(function(a, b) {
			var i = numParents(skeletonBones[a]);
			var j = numParents(skeletonBones[b]);
			return i < j ? -1 : i > j ? 1 : 0;
		});

	}

	function setAction(action: String) {
		armature.initMats();
		var a = armature.getAction(action);
		skeletonBones = a.bones;
		skeletonMats = a.mats;
		if(! rootMotionCacheInit) skeletonMats.push(Mat4.identity());
		rootMotionCacheInit = true;
		setMats();
	}

	function getAction(action: String): Array<TObj> {
		armature.initMats();
		return armature.getAction(action).bones;
	}

	function multParent(i: Int, fasts: Array<Mat4>, bones: Array<TObj>, mats: Array<Mat4>) {
		var f = fasts[i];
		if (applyParent != null && !applyParent[i]) {
			f.setFrom(mats[i]);
			return;
		}
		var p = bones[i].parent;
		var bi = getBoneIndex(p, bones);
		(p == null || bi == -1) ? f.setFrom(mats[i]) : f.multmats(fasts[bi], mats[i]);
	}

	inline function multVecs(vec1: Vec4, vec2: Vec4): Vec4 {
		var res = new Vec4().setFrom(vec1);
		res.x *= vec2.x;
		res.y *= vec2.y;
		res.z *= vec2.z;
		res.w *= vec2.w;

		return res;

	}

	// Do animation here
	public function setAnimationLoop(f: Array<Mat4>->Void) {
		updateAnimation = f;
	}

	override public function play(action = "", onComplete: Void->Void = null, blendTime = 0.2, speed = 1.0, loop = true) {
		super.play(action, onComplete, blendTime, speed, loop);
		if (action != "") {
			setAction(action);
			var tempAnimParam = new ActionSampler(action);
			registerAction("tempAction", tempAnimParam);
			updateAnimation = function(mats){
				sampleAction(tempAnimParam, mats);
			}
		}
	}

	override public function update(delta: FastFloat) {
		this.delta = delta;
		if (!isSkinned && skeletonBones == null) setAction(armature.actions[0].name);
		if (object != null && (!object.visible || object.culled)) return;
		if (skeletonBones == null || skeletonBones.length == 0) return;

		#if arm_debug
		Animation.beginProfile();
		#end

		super.update(delta);
		if(updateAnimation != null) {
			
			updateAnimation(skeletonMats);
		}

		updateConstraints();
		// Do forward kinematics and inverse kinematics here
		if (onUpdates != null) {
			var i = 0;
			var l = onUpdates.length;
			while (i < l) {
				onUpdates[i]();
				l <= onUpdates.length ? i++ : l = onUpdates.length;
			}
		}

		// Calc absolute bones
		for (i in 0...skeletonBones.length) {
			// Take bones with 0 parents first
			multParent(matsFastSort[i], matsFast, skeletonBones, skeletonMats);
		}
		if (isSkinned) updateSkinGpu();
		else updateBonesOnly();

		#if arm_debug
		Animation.endProfile();
		#end
	}

	public function evaluateRootMotion(actionMats: Array<Mat4>): Vec4{
		if(rootMotionIndex < 0) return new Vec4();
		var scl = armatureObject.transform.scale;
		wm = getRootMotionWorldMat(actionMats, rootMotion);
		wm.decompose(vpos, q1, vscl);
		vpos = multVecs(vpos, scl);
		rootMotionVelocity.setFrom(vpos);
		rootMotionRotation.setFrom(q1);
		return new Vec4().setFrom(rootMotionVelocity);
		
	}

	public function setRootMotion(bone: TObj, lockX: Bool = false, lockY: Bool = false, lockZ: Bool = false) {
		rootMotion = bone;
		rootMotionIndex = getBoneIndex(rootMotion);
		rootMotionLockX	= lockX;
		rootMotionLockY	= lockY;
		rootMotionLockZ	= lockZ;
		rootMotionVelocity = new Vec4();
		rootMotionRotation = new Quat();
	}

	function multParents(m: Mat4, i: Int, bones: Array<TObj>, mats: Array<Mat4>) {
		var bone = bones[i];
		var p = bone.parent;
		while (p != null) {
			var i = getBoneIndex(p, bones);
			if (i == -1) continue;
			m.multmat(mats[i]);
			p = p.parent;
		}
	}

	function getConstraintsFromScene(cs: Array<TConstraint>) {
		// Init constraints
		if (constraintTargets == null) {
			constraintTargets = [];
			constraintTargetsI = [];
			for (c in cs) {
				var o = Scene.active.getChild(c.target);
				constraintTargets.push(o);
				var m: Mat4 = null;
				if (o != null) {
					m = Mat4.identity().setFrom(o.transform.world);
					m.getInverse(m);
				}
				constraintTargetsI.push(m);
			}
			constraintMats = new Map();
		}
	}

	function getConstraintsFromParentRelative(cs: Array<TConstraint>) {
		// Init constraints
		if (constraintTargets == null) {
			constraintTargets = [];
			constraintTargetsI = [];
			// MeshObject -> ArmatureObject -> Collection/Empty
			var conParent = armatureObject.parent;
			if (conParent == null) return;
			for (c in cs) {
				var o = conParent.getChild(c.target);
				constraintTargets.push(o);
				var m: Mat4 = null;
				if (o != null) {
					m = Mat4.identity().setFrom(o.transform.world);
					m.getInverse(m);
				}
				constraintTargetsI.push(m);
			}
			constraintMats = new Map();
		}
	}

	function updateConstraints() {
		if (data == null) return;
		var cs = data.raw.skin.constraints;
		if (cs == null) return;
		if (relativeBoneConstraints) {
			getConstraintsFromParentRelative(cs);
		}
		else {
			getConstraintsFromScene(cs);
		}
		// Update matrices
		for (i in 0...cs.length) {
			var c = cs[i];
			var bone = getBone(c.bone);
			if (bone == null) continue;
			var o = constraintTargets[i];
			if (o == null) continue;
			if (c.type == "CHILD_OF") {
				var m = constraintMats.get(bone);
				if (m == null) {
					m = Mat4.identity();
					constraintMats.set(bone, m);
				}
				m.setFrom(armatureObject.transform.world); // Armature transform
				m.multmat(constraintTargetsI[i]); // Roll back initial hitbox transform
				m.multmat(o.transform.world); // Current hitbox transform
				m1.getInverse(armatureObject.transform.world); // Roll back armature transform
				m.multmat(m1);
			}
		}
	}

	var onUpdates: Array<Void->Void> = null;
	public function notifyOnUpdate(f: Void->Void) {
		if (onUpdates == null) onUpdates = [];
		onUpdates.push(f);
	}

	public function removeUpdate(f: Void->Void) {
		onUpdates.remove(f);
	}

	override public function updateActionTrack(sampler: ActionSampler) {
		if(sampler.paused) return;

		if(! sampler.actionDataInit) {
			var bones = getAction(sampler.action);
			sampler.setBoneAction(bones);
		}
		
		var bones = sampler.getBoneAction();
		for(b in bones){
			if (b.anim != null) {
				updateTrack(b.anim, sampler);
				break;
			}
		}
	}

	public function sampleAction(sampler: ActionSampler, actionMats: Array<Mat4>) {

		if(! sampler.actionDataInit) {
			var bones = getAction(sampler.action);
			sampler.setBoneAction(bones);
		}
		
		var bones = sampler.getBoneAction();
		actionMats[skeletonBones.length].setIdentity();
		var rootMotionEnabled = sampler.rootMotionPos || sampler.rootMotionRot;
		for (i in 0...bones.length) {
			if (i == rootMotionIndex && rootMotionEnabled){
				updateAnimSampledRootMotion(bones[i].anim, actionMats[i], actionMats[skeletonBones.length], sampler);
			}
			else {
				updateAnimSampled(bones[i].anim, actionMats[i], sampler);
			}
		}

	}

	function updateAnimSampled(anim: TAnimation, mm: Mat4, sampler: ActionSampler) {

		if(anim == null) return;
		var track = anim.tracks[0];
		var sign = sampler.speed > 0 ? 1 : -1;

		var t = sampler.time;
		//t = t < 0 ? 0.1 : t;

		var ti = sampler.offset;
		//ti = ti < 0 ? 1 : ti;

		interpoateSample(track, mm, t, ti, sign);
	}

	function updateAnimSampledRootMotion(anim: TAnimation, mm: Mat4, rm: Mat4, sampler: ActionSampler) {
		if(anim == null) return;
		var track = anim.tracks[0];
		var sign = sampler.speed > 0 ? 1 : -1;

		var t0 = speed > 0 ? 0 : track.frames.length - 1;
		var t = sampler.time;
		var ti = sampler.offset;

		if(sampler.trackEnd || !sampler.cacheInit) {
			interpoateSample(track, bm, t, ti, sign);
			//bm.setF32(track.values, t0);
			sampler.setActionCache(bm);
		}

		// Interpolated action for current frame
		interpoateSample(track, m1, t, ti, sign);
		// Action at first frame
		m.setF32(track.values, t0);
		// Action at previous frame
		sampler.getActionCache(m2);

		m.decompose(vpos, q1, vscl);
		m1.decompose(vpos2, q2, vscl2);
		m2.decompose(vpos3, q3, vscl3);

		// Compose
		if(sampler.rootMotionRot) {
			// Bone matrix
			mm.fromQuat(q1);
			mm.scale(vscl2);
			// Root motion matrix
			q2.mult(q4.inverse(q3));
			rm.fromQuat(q2);
		}
		else {
			// Bone matrix
			mm.fromQuat(q2);
			mm.scale(vscl2);
		}

		if(sampler.rootMotionPos) {
			// Bone matrix
			mm._30 = vpos.x;
			mm._31 = vpos.y;
			mm._32 = vpos.z;
			// Root motion matrix
			rm._30 = vpos2.x - vpos3.x;
			rm._31 = vpos2.y - vpos3.y;
			rm._32 = vpos2.z - vpos3.z;
		}
		else {
			// Bone matrix
			mm._30 = vpos2.x;
			mm._31 = vpos2.y;
			mm._32 = vpos2.z;
		}

		sampler.setActionCache(m1);
	}


	inline function interpoateSample(track: TTrack, m: Mat4, t: FastFloat, ti: Int, sign: Int) {
		var t1 = track.frames[ti] * frameTime;
		var t2 = track.frames[ti + sign] * frameTime;
		var s: FastFloat = (t - t1) / (t2 - t1); // Linear

		m1.setF32(track.values, ti * 16); // Offset to 4x4 matrix array
		m2.setF32(track.values, (ti + sign) * 16);

		// Decompose
		m1.decompose(vpos, q1, vscl);
		m2.decompose(vpos2, q2, vscl2);

		// Lerp
		v1.lerp(vpos, vpos2, s);
		v2.lerp(vscl, vscl2, s);
		q3.lerp(q1, q2, s);

		// Compose
		m.fromQuat(q3);
		m.scale(v2);
		m._30 = v1.x;
		m._31 = v1.y;
		m._32 = v1.z;
	}

	function updateBonesOnly() {
		if (boneChildren != null) {
			for (i in 0...skeletonBones.length) {
				var b = skeletonBones[i]; // TODO: blendTime > 0
				m.setFrom(matsFast[i]);
				updateBoneChildren(b, m);
			}
		}
	}

	function updateSkinGpu() {
		var bones = skeletonBones;

		// Update skin buffer
		for (i in 0...bones.length) {
			if (constraintMats != null) {
				var m = constraintMats.get(bones[i]);
				if (m != null) {
					updateSkinBuffer(m, i);
					continue;
				}
			}

			m.setFrom(matsFast[i]);

			if (absMats != null && i < absMats.length) absMats[i].setFrom(m);
			if (boneChildren != null) updateBoneChildren(bones[i], m);

			m.multmats(m, data.geom.skeletonTransformsI[i]);
			updateSkinBuffer(m, i);
		}
	}

	function updateSkinBuffer(m: Mat4, i: Int) {
		// Dual quat skinning
		m.decompose(vpos, q1, vscl);
		q1.normalize();
		q2.set(vpos.x, vpos.y, vpos.z, 0.0);
		q2.multquats(q2, q1);
		skinBuffer[i * 12] = q1.x; // Real
		skinBuffer[i * 12 + 1] = q1.y;
		skinBuffer[i * 12 + 2] = q1.z;
		skinBuffer[i * 12 + 3] = q1.w;
		skinBuffer[i * 12 + 4] = q2.x * 0.5; // Dual
		skinBuffer[i * 12 + 5] = q2.y * 0.5;
		skinBuffer[i * 12 + 6] = q2.z * 0.5;
		skinBuffer[i * 12 + 7] = q2.w * 0.5;
		skinBuffer[i * 12 + 8] = vscl.x;
		skinBuffer[i * 12 + 9] = vscl.y;
		skinBuffer[i * 12 + 10] = vscl.z;
		skinBuffer[i * 12 + 11] = 1.0;

	}

	public override function getTotalFrames(sampler: ActionSampler): Int {
		var bones = getAction(sampler.action);
		var track = bones[0].anim.tracks[0];
		return Std.int(track.frames[track.frames.length - 1] - track.frames[0]);
	}

	public function getBone(name: String): TObj {
		if (skeletonBones == null) return null;
		for (b in skeletonBones) if (b.name == name) return b;
		return null;
	}

	function getBoneIndex(bone: TObj, bones: Array<TObj> = null): Int {
		if (bones == null) bones = skeletonBones;
		if (bones != null) for (i in 0...bones.length) if (bones[i] == bone) return i;
		return -1;
	}

	public function getBoneMat(actionMats: Array<Mat4>, bone: TObj): Mat4 {
		return actionMats != null ? actionMats[getBoneIndex(bone)] : null;
	}

	function getWorldMat(actionMats: Array<Mat4>, bone: TObj): Mat4 {
		if (applyParent == null) {
			applyParent = [];
			for (m in actionMats) applyParent.push(true);
		}
		var i = getBoneIndex(bone);
		wm.setFrom(actionMats[i]);
		multParents(wm, i, skeletonBones, actionMats);
		return wm;
	}

	function getRootMotionWorldMat(actionMats: Array<Mat4>, bone: TObj): Mat4 {
		// Get root motion bone index
		var i = getBoneIndex(bone);
		// Store current bone matrix in temp
		var tempMat = Mat4.identity().setFrom(actionMats[i]);
		// Move root motion cache to bone position
		actionMats[i].setFrom(actionMats[skeletonBones.length]);
		// Calculate world matrix
		wm.setFrom(getWorldMat(actionMats, bone));
		// Revert to old value
		actionMats[i].setFrom(tempMat);
		return wm;
	}

	// Returns bone matrix in world space
	public function getAbsWorldMat(actionMats: Array<Mat4>, bone: TObj): Mat4 {
		var wm = getWorldMat(actionMats, bone);
		wm.multmat(armatureObject.transform.world);
		return wm;
	}

	// Returns an array of bone matrices in world space
	public function getWorldMatsFast(actionMats: Array<Mat4>, tip: TObj, chainLength: Int): Array<Mat4> {
		var wmArray: Array<Mat4> = [];
		var root = tip;
		var numP = chainLength;
		for (i in 0...chainLength) {
			var wm = getAbsWorldMat(actionMats, root);
			wmArray[chainLength - 1 - i] = wm.clone();
			root = root.parent;
			numP--;
		}

		// Root bone at [0]
		return wmArray;
	}

	// Set bone transforms in world space
	public function setBoneMatFromWorldMat(actionMats: Array<Mat4>, wm: Mat4, bone: TObj) {
		var invMat = Mat4.identity();
		var tempMat = wm.clone();
		invMat.getInverse(armatureObject.transform.world);
		tempMat.multmat(invMat);
		var bones: Array<TObj> = [];
		var pBone = bone;
		while (pBone.parent != null) {
			bones.push(pBone.parent);
			pBone = pBone.parent;
		}

		for (i in 0...bones.length) {
			var x = bones.length - 1;
			invMat.getInverse(getBoneMat(actionMats, bones[x - i]));
			tempMat.multmat(invMat);
		}

		getBoneMat(actionMats, bone).setFrom(tempMat);
	}

	public function blendAction(actionMats1: Array<Mat4>, actionMats2: Array<Mat4>, resultMat: Array<Mat4>, factor: FastFloat = 0.0, layerMask: Int = -1, threshold: FastFloat = 0.1) {

		if(factor < threshold) {
			for(i in 0...actionMats1.length){
				// Use Action 1
				resultMat[i].setFrom(actionMats1[i]);
			}
		}
		else if(factor > 1.0 - threshold){
			for(i in 0...actionMats2.length){
				// If root motion cache -> use root motion index, else use current index
				var j = i == skeletonBones.length ? rootMotionIndex : i;
				// Skip if root motion is disabled
				if(j < 0) continue;
				// Use Action 2
				if(skeletonBones[j].bone_layers[layerMask] || layerMask < 0){
					resultMat[i].setFrom(actionMats2[i]);
				}
				// Use Action 1 if not in layer
				else {
					resultMat[i].setFrom(actionMats1[i]);
				}
			}
		}
		else {
			for(i in 0...actionMats1.length){
				// If root motion cache -> use root motion index, else use current index
				var j = i == skeletonBones.length ? rootMotionIndex : i;
				// Skip if root motion is disabled
				if(j < 0) continue;
				// Blend
				if(skeletonBones[j].bone_layers[j] || layerMask < 0) {
					// Decompose
					m.setFrom(actionMats1[i]);
					m1.setFrom(actionMats2[i]);
					m.decompose(vpos, q1, vscl);
					m1.decompose(vpos2, q2, vscl2);
					// Lerp
					v1.lerp(vpos, vpos2, factor);
					v2.lerp(vscl, vscl2, factor);
					q3.lerp(q1, q2, factor);
					// Compose
					m2.fromQuat(q3);
					m2.scale(v2);
					m2._30 = v1.x;
					m2._31 = v1.y;
					m2._32 = v1.z;
					// Lock root motion to one action on certain axis to conserve looping
					if(i == skeletonBones.length){
						m2._30 = rootMotionLockX ? vpos2.x : m2._30;
						m2._31 = rootMotionLockY ? vpos2.y : m2._31;
						m2._32 = rootMotionLockZ ? vpos2.z : m2._32;
					}
					// Return Result
					resultMat[i].setFrom(m2);
				}
				// Use Action 1 if not in layer
				else {
					resultMat[i].setFrom(actionMats1[i]);
				}
			}
		}
	}

	public function additiveBlendAction(baseActionMats: Array<Mat4>, addActionMats: Array<Mat4>, restPoseMats: Array<Mat4>, resultMat: Array<Mat4>, factor: FastFloat, layerMask: Int = -1, threshold: FastFloat = 0.1) {

		if(factor < threshold) {
			for(i in 0...baseActionMats.length){
				resultMat[i].setFrom(baseActionMats[i]);
			}
		}
		else{
			for(i in 0...baseActionMats.length){

				if(skeletonBones[i].bone_layers[layerMask] || layerMask < 0) {
					// Decompose
					m.setFrom(baseActionMats[i]);
					m1.setFrom(addActionMats[i]);
					bm.setFrom(restPoseMats[i]);

					m.decompose(vpos, q1, vscl);
					m1.decompose(vpos2, q2, vscl2);
					bm.decompose(vpos3, q3, vscl3);

					// Add Transforms
					v1.setFrom(vpos);
					v2.setFrom(vpos2);
					v2.sub(vpos3);
					v2.mult(factor);
					v1.add(v2);

					// Add Scales
					vscl2.mult(factor);
					v2.set(1-factor, 1-factor, 1-factor, 1);
					v2.add(vscl2);
					v2.x *= vscl.x;
					v2.y *= vscl.y;
					v2.z *= vscl.z;
					v2.w = 1.0;

					// Add rotations
					q2.lerp(q3, q2, factor);
					wm.fromQuat(q3);
					wm.getInverse(wm);
					q3.fromMat(wm).normalize();
					q3.multquats(q3, q2);
					q3.multquats(q1, q3);

					// Compose
					m2.fromQuat(q3);
					m2.scale(v2);
					m2._30 = v1.x;
					m2._31 = v1.y;
					m2._32 = v1.z;
					// Return Result
					resultMat[i].setFrom(m2);
				}
				else{
					resultMat[i].setFrom(baseActionMats[i]);
				}
			}
		}
	}

	public function solveIK(actionMats: Array<Mat4>, effector: TObj, goal: Vec4, precision = 0.01, maxIterations = 100, chainLenght = 100, pole: Vec4 = null, rollAngle = 0.0) {
		// Array of bones to solve IK for, effector at 0
		var bones: Array<TObj> = [];

		// Array of bones lengths, effector length at 0
		var lengths: Array<FastFloat> = [];

		// Array of bones matrices in world coordinates, effector at 0
		var boneWorldMats: Array<Mat4>;

		var tempLoc = new Vec4();
		var tempRot = new Quat();
		var tempRot2 = new Quat();
		var tempScl = new Vec4();
		var roll = new Quat().fromEuler(0, rollAngle, 0);

		// Store all bones and lengths in array
		var tip = effector;
		bones.push(tip);
		var root = tip;

		while (root.parent != null) {
			if (bones.length > chainLenght - 1) break;
			bones.push(root.parent);
			root = root.parent;
		}

		// Get all bone mats in world space
		boneWorldMats = getWorldMatsFast(actionMats, effector, bones.length);

		var tempIndex = 0;
		for(b in bones){
			lengths.push(b.bone_length * boneWorldMats[boneWorldMats.length - 1 - tempIndex].getScale().x);
			tempIndex++;
		}

		// Root bone
		root = bones[bones.length - 1];

		// World matrix of root bone
		var rootWorldMat = getAbsWorldMat(actionMats, root).clone();
		// Distance from root to goal
		var dist = Vec4.distance(goal, rootWorldMat.getLoc());


		// Total bones length
		var totalLength: FastFloat = 0.0;
		for (l in lengths) totalLength += l;

		// Unreachable distance
		if (dist > totalLength) {
			// Calculate unit vector from root to goal
			var newLook = goal.clone();
			newLook.sub(rootWorldMat.getLoc());
			newLook.normalize();

			// Rotate root bone to point at goal
			rootWorldMat.decompose(tempLoc, tempRot, tempScl);
			tempRot2.fromTo(rootWorldMat.look().normalize(), newLook);
			tempRot2.mult(tempRot);
			tempRot2.mult(roll);
			rootWorldMat.compose(tempLoc, tempRot2, tempScl);

			// Set bone matrix in local space from world space
			setBoneMatFromWorldMat(actionMats, rootWorldMat, root);

			// Set child bone rotations to zero
			for (i in 0...bones.length - 1) {
				getBoneMat(actionMats, bones[i]).decompose(tempLoc, tempRot, tempScl);
				getBoneMat(actionMats, bones[i]).compose(tempLoc, roll, tempScl);
			}
			return;
		}

		// Array of bone locations in world space, root location at [0]
		var boneWorldLocs: Array<Vec4> = [];
		for (b in boneWorldMats) boneWorldLocs.push(b.getLoc());

		// Solve FABRIK
		var vec = new Vec4();
		var startLoc = boneWorldLocs[0].clone();
		var l = boneWorldLocs.length;
		var testLength = 0;

		for (iter in 0...maxIterations) {
			// Backward
			vec.setFrom(goal);
			vec.sub(boneWorldLocs[l - 1]);
			vec.normalize();
			vec.mult(lengths[0]);
			boneWorldLocs[l - 1].setFrom(goal);
			boneWorldLocs[l - 1].sub(vec);

			for (j in 1...l) {
				vec.setFrom(boneWorldLocs[l - 1 - j]);
				vec.sub(boneWorldLocs[l - j]);
				vec.normalize();
				vec.mult(lengths[j]);
				boneWorldLocs[l - 1 - j].setFrom(boneWorldLocs[l - j]);
				boneWorldLocs[l - 1 - j].add(vec);
			}

			// Forward
			boneWorldLocs[0].setFrom(startLoc);
			for (j in 1...l) {
				vec.setFrom(boneWorldLocs[j]);
				vec.sub(boneWorldLocs[j - 1]);
				vec.normalize();
				vec.mult(lengths[l - j]);
				boneWorldLocs[j].setFrom(boneWorldLocs[j - 1]);
				boneWorldLocs[j].add(vec);
			}

			if (Vec4.distance(boneWorldLocs[l - 1], goal) - lengths[0] <= precision) break;
		}

		// Pole rotation implementation
		if (pole != null) {
			for (i in 1...boneWorldLocs.length - 1) {
				boneWorldLocs[i] = moveTowardPole(boneWorldLocs[i - 1].clone(), boneWorldLocs[i].clone(), boneWorldLocs[i + 1].clone(), pole.clone());
			}
		}

		// Correct rotations
		// Applying locations and rotations
		var tempLook = new Vec4();
		var tempLoc2 = new Vec4();

		for (i in 0...l - 1){
			// Decompose matrix
			boneWorldMats[i].decompose(tempLoc, tempRot, tempScl);

			// Rotate to point to parent bone
			tempLoc2.setFrom(boneWorldLocs[i + 1]);
			tempLoc2.sub(boneWorldLocs[i]);
			tempLoc2.normalize();
			tempLook.setFrom(boneWorldMats[i].look());
			tempLook.normalize();
			tempRot2.fromTo(tempLook, tempLoc2);
			tempRot2.mult(tempRot);
			tempRot2.mult(roll);

			// Compose matrix with new rotation and location
			boneWorldMats[i].compose(boneWorldLocs[i], tempRot2, tempScl);

			// Set bone matrix in local space from world space
			setBoneMatFromWorldMat(actionMats, boneWorldMats[i], bones[bones.length - 1 - i]);
		}

		// Decompose matrix
		boneWorldMats[l - 1].decompose(tempLoc, tempRot, tempScl);

		// Rotate to point to goal
		tempLoc2.setFrom(goal);
		tempLoc2.sub(tempLoc);
		tempLoc2.normalize();
		tempLook.setFrom(boneWorldMats[l - 1].look());
		tempLook.normalize();
		tempRot2.fromTo(tempLook, tempLoc2);
		tempRot2.mult(tempRot);
		tempRot2.mult(roll);

		// Compose matrix with new rotation and location
		boneWorldMats[l - 1].compose(boneWorldLocs[l - 1], tempRot2, tempScl);

		// Set bone matrix in local space from world space
		setBoneMatFromWorldMat(actionMats, boneWorldMats[l - 1], bones[0]);
	}

	public function moveTowardPole(bone0Pos: Vec4, bone1Pos: Vec4, bone2Pos: Vec4, polePos: Vec4): Vec4 {
		// Setup projection plane at current bone's parent
		var plane = new Plane();

		// Plane normal from parent of current bone to child of current bone
		var planeNormal = new Vec4().setFrom(bone2Pos);
		planeNormal.sub(bone0Pos);
		planeNormal.normalize();
		plane.set(planeNormal, bone0Pos);

		// Create and project ray from current bone to plane
		var rayPos = new Vec4();
		rayPos.setFrom(bone1Pos);
		var rayDir = new Vec4();
		rayDir.sub(planeNormal);
		rayDir.normalize();
		var rayBone = new Ray(rayPos, rayDir);

		// Projection point of current bone on plane
		// If pole does not project on the plane
		if (!rayBone.intersectsPlane(plane)) {
			rayBone.direction = planeNormal;
		}

		var bone1Proj = rayBone.intersectPlane(plane);

		// Create and project ray from pole to plane
		rayPos.setFrom(polePos);
		var rayPole = new Ray(rayPos, rayDir);

		// If pole does not project on the plane
		if (!rayPole.intersectsPlane(plane)) {
			rayPole.direction = planeNormal;
		}

		// Projection point of pole on plane
		var poleProj = rayPole.intersectPlane(plane);

		// Caclulate unit vectors from pole projection to parent bone
		var poleProjNormal = new Vec4();
		poleProjNormal.setFrom(bone0Pos);
		poleProjNormal.sub(poleProj);
		poleProjNormal.normalize();

		// Calculate unit vector from current bone projection to parent bone
		var bone1ProjNormal = new Vec4();
		bone1ProjNormal.setFrom(bone0Pos);
		bone1ProjNormal.sub(bone1Proj);
		bone1ProjNormal.normalize();

		// Calculate rotation quaternion
		var rotQuat = new Quat();
		rotQuat.fromTo(bone1ProjNormal, poleProjNormal);

		// Apply quaternion to current bone location
		var bone1Res = new Vec4().setFrom(bone1Pos);
		bone1Res.sub(bone0Pos);
		bone1Res.applyQuat(rotQuat);
		bone1Res.add(bone0Pos);

		// Return new location of current bone
		return bone1Res;
	}

	public function solveTwoBoneIK(actionMats : Array<Mat4>, effector: TObj, goal: Vec4, pole: Vec4 = null, rollAngle = 0.0) {		
		var roll = new Quat().fromEuler(0, rollAngle, 0);
		var root = effector.parent;

		// Get bone transforms in world space
		var effectorMat = getAbsWorldMat(actionMats, effector).clone();
		var rootMat = getAbsWorldMat(actionMats, root).clone();

		// Get bone lenghts
		var effectorLen = effector.bone_length * effectorMat.getScale().x;
		var rootLen = root.bone_length * rootMat.getScale().x;

		// Get distance form root to goal
		var goalLen = Math.abs(Vec4.distance(rootMat.getLoc(), goal));

		var totalLength = effectorLen + rootLen;

		// Get tip location of effector bone
		var effectorTipPos = new Vec4().setFrom(effectorMat.look()).normalize();
		effectorTipPos.mult(effectorLen);
		effectorTipPos.add(effectorMat.getLoc());

		// Get unit vector from root to effector tip
		var vectorRootEffector = new Vec4().setFrom(effectorTipPos).sub(rootMat.getLoc());
		vectorRootEffector.normalize();

		// Get unit vector from root to goal
		var vectorGoal = new Vec4().setFrom(goal).sub(rootMat.getLoc());
		vectorGoal.normalize();

		// Get unit vector of root bone
		var vectorRoot = new Vec4().setFrom(rootMat.look()).normalize();

		// Get unit vector of effector bone
		var vectorEffector = new Vec4().setFrom(effectorMat.look()).normalize();		
		
		// Get dot product of vectors
		var dot = new Vec4().setFrom(vectorRootEffector).dot(vectorRoot);
		// Calmp between -1 and 1
		dot = dot < -1.0 ? -1.0 : dot > 1.0 ? 1.0 : dot;
		// Gat angle A1
		var angleA1 = Math.acos(dot);

		// Get angle A2
		dot = new Vec4().setFrom(vectorRoot).mult(-1.0).dot(vectorEffector);
		dot = dot < -1.0 ? -1.0 : dot > 1.0 ? 1.0 : dot;
		var angleA2 = Math.acos(dot);

		// Get angle A3
		dot = new Vec4().setFrom(vectorRootEffector).dot(vectorGoal);
		dot = dot < -1.0 ? -1.0 : dot > 1.0 ? 1.0 : dot;
		var angleA3 = Math.acos(dot);

		// Get angle B1
		dot = (effectorLen * effectorLen - rootLen * rootLen - goalLen * goalLen) / (-2 * rootLen * goalLen);
		dot = dot < -1.0 ? -1.0 : dot > 1.0 ? 1.0 : dot;
		var angleB1 = Math.acos(dot);

		// Get angle B2
		dot = (goalLen * goalLen - rootLen * rootLen - effectorLen * effectorLen) / (-2 * rootLen * effectorLen);
		dot = dot < -1.0 ? -1.0 : dot > 1.0 ? 1.0 : dot;
		var angleB2 = Math.acos(dot);

		// Calculate rotation axes
		var axis0 = new Vec4().setFrom(vectorRootEffector).cross(vectorRoot).normalize();
		var axis1 = new Vec4().setFrom(vectorRootEffector).cross(vectorGoal).normalize();

		// Apply rotations to effector bone
		vpos.setFrom(effectorMat.getLoc());
		effectorMat.setLoc(new Vec4());
		effectorMat.applyQuat(new Quat().fromAxisAngle(axis0, angleB2 - angleA2));
		effectorMat.setLoc(vpos);
		setBoneMatFromWorldMat(actionMats, effectorMat, effector);

		// Apply rotations to root bone
		vpos.setFrom(rootMat.getLoc());
		rootMat.setLoc(new Vec4());
		rootMat.applyQuat(new Quat().fromAxisAngle(axis0, angleB1 - angleA1));
		rootMat.applyQuat(new Quat().fromAxisAngle(axis1, angleA3));
		rootMat.setLoc(vpos);
		setBoneMatFromWorldMat(actionMats, rootMat, root);

		// Recalculate new effector matrix
		effectorMat.setFrom(getAbsWorldMat(actionMats, effector));

		// Check if pole present
		if((pole != null) && (goalLen < totalLength)) {
		
			// Calculate new effector tip position
			vscl.setFrom(effectorMat.look()).normalize();
			vscl.mult(effectorLen);
			vscl.add(effectorMat.getLoc());

			// Calculate new effector position from pole
			vpos2 = moveTowardPole(rootMat.getLoc(), effectorMat.getLoc(), vscl, pole);

			// Orient root bone to new effector position
			vpos.setFrom(rootMat.getLoc());
			rootMat.setLoc(new Vec4());
			vpos3.setFrom(vpos2).sub(vpos).normalize();
			rootMat.applyQuat(new Quat().fromTo(rootMat.look().normalize(), vpos3));
			rootMat.setLoc(vpos);
			
			// Orient effector bone to new position
			vpos.setFrom(effectorMat.getLoc());
			effectorMat.setLoc(new Vec4());
			vpos3.setFrom(vscl).sub(vpos2).normalize();
			effectorMat.applyQuat(new Quat().fromTo(effectorMat.look().normalize(), vpos3));
			effectorMat.setLoc(vpos2);
		}

		// Apply roll to root bone
		vpos.setFrom(rootMat.getLoc());
		rootMat.setLoc(new Vec4());
		rootMat.applyQuat(new Quat().fromAxisAngle(rootMat.look().normalize(), rollAngle));
		rootMat.setLoc(vpos);

		// Apply roll to effector bone
		vpos.setFrom(effectorMat.getLoc());
		effectorMat.setLoc(new Vec4());
		effectorMat.applyQuat(new Quat().fromAxisAngle(effectorMat.look().normalize(), rollAngle));
		effectorMat.setLoc(vpos);

		// Finally set root and effector matrices in local space
		setBoneMatFromWorldMat(actionMats, rootMat, root);
		setBoneMatFromWorldMat(actionMats, effectorMat, effector);

	}

}
#end