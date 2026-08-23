package iron.object;

import iron.data.SceneFormat;
import iron.math.Vec4;
import iron.math.Quat;
import iron.math.Mat4;

class Constraint {
	var raw: TConstraint;
	var target: Transform = null;

	public function new(constraint: TConstraint) {
		raw = constraint;
	}

	public function apply(transform: Transform) {
		if (target == null && raw.target != null) {
			var obj = Scene.active.getChild(raw.target);
			if (obj != null) target = obj.transform;
		}

		if (target == null && raw.type != "LIMIT_LOCATION" && raw.type != "LIMIT_ROTATION" && raw.type != "LIMIT_SCALE") return;

		if (raw.type == "COPY_LOCATION") {
			if (raw.use_offset) {
				if (raw.use_x) transform.world._30 += target.world._30;
				if (raw.use_y) transform.world._31 += target.world._31;
				if (raw.use_z) transform.world._32 += target.world._32;
			}
			else {
				if (raw.use_x) transform.world._30 = target.world._30;
				if (raw.use_y) transform.world._31 = target.world._31;
				if (raw.use_z) transform.world._32 = target.world._32;
			}
		}

		else if (raw.type == "COPY_ROTATION") {
			var tq = target.rot;
			var mq = transform.rot;
			if (raw.use_offset) {
				mq.mult(tq);
			}
			else {
				if (raw.use_x) mq.x = tq.x;
				if (raw.use_y) mq.y = tq.y;
				if (raw.use_z) mq.z = tq.z;
				mq.w = tq.w;
			}
			var loc = new Vec4(transform.world._30, transform.world._31, transform.world._32);
			var scale = transform.scale;
			transform.world.compose(loc, mq, scale);
		}

		else if (raw.type == "COPY_SCALE") {
			var ts = target.scale;
			if (raw.use_offset) {
				if (raw.use_x) transform.scale.x *= ts.x;
				if (raw.use_y) transform.scale.y *= ts.y;
				if (raw.use_z) transform.scale.z *= ts.z;
			}
			else {
				if (raw.use_x) transform.scale.x = ts.x;
				if (raw.use_y) transform.scale.y = ts.y;
				if (raw.use_z) transform.scale.z = ts.z;
			}
			var loc = new Vec4(transform.world._30, transform.world._31, transform.world._32);
			transform.world.compose(loc, transform.rot, transform.scale);
		}

		else if (raw.type == "COPY_TRANSFORMS") {
			transform.world.setFrom(target.world);
		}

		else if (raw.type == "LIMIT_LOCATION") {
			if (raw.use_min_x && transform.world._30 < raw.min_x) transform.world._30 = raw.min_x;
			if (raw.use_max_x && transform.world._30 > raw.max_x) transform.world._30 = raw.max_x;
			
			if (raw.use_min_y && transform.world._31 < raw.min_y) transform.world._31 = raw.min_y;
			if (raw.use_max_y && transform.world._31 > raw.max_y) transform.world._31 = raw.max_y;
			
			if (raw.use_min_z && transform.world._32 < raw.min_z) transform.world._32 = raw.min_z;
			if (raw.use_max_z && transform.world._32 > raw.max_z) transform.world._32 = raw.max_z;
		}

		else if (raw.type == "LIMIT_ROTATION") {
			var euler = transform.rot.getEuler();
			var changed = false;

			if (raw.use_limit_x) {
				if (euler.x < raw.min_x) { euler.x = raw.min_x; changed = true; }
				if (euler.x > raw.max_x) { euler.x = raw.max_x; changed = true; }
			}
			if (raw.use_limit_y) {
				if (euler.y < raw.min_y) { euler.y = raw.min_y; changed = true; }
				if (euler.y > raw.max_y) { euler.y = raw.max_y; changed = true; }
			}
			if (raw.use_limit_z) {
				if (euler.z < raw.min_z) { euler.z = raw.min_z; changed = true; }
				if (euler.z > raw.max_z) { euler.z = raw.max_z; changed = true; }
			}

			if (changed) {
				transform.rot.fromEuler(euler.x, euler.y, euler.z);
				var loc = new Vec4(transform.world._30, transform.world._31, transform.world._32);
				transform.world.compose(loc, transform.rot, transform.scale);
			}
		}

		else if (raw.type == "LIMIT_SCALE") {
			if (raw.use_min_x && transform.scale.x < raw.min_x) transform.scale.x = raw.min_x;
			if (raw.use_max_x && transform.scale.x > raw.max_x) transform.scale.x = raw.max_x;

			if (raw.use_min_y && transform.scale.y < raw.min_y) transform.scale.y = raw.min_y;
			if (raw.use_max_y && transform.scale.y > raw.max_y) transform.scale.y = raw.max_y;

			if (raw.use_min_z && transform.scale.z < raw.min_z) transform.scale.z = raw.min_z;
			if (raw.use_max_z && transform.scale.z > raw.max_z) transform.scale.z = raw.max_z;

			var loc = new Vec4(transform.world._30, transform.world._31, transform.world._32);
			transform.world.compose(loc, transform.rot, transform.scale);
		}
	}
}