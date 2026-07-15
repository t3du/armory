package armory.trait;

import iron.Trait;
import iron.math.Vec4;
import iron.math.Quat;
import iron.system.Time;
#if arm_navigation
import armory.trait.navigation.Navigation;
#end

class NavAgent extends Trait {

	@prop public var speed: Float = 5;
	@prop public var turnDuration: Float = 0.4;
	@prop public var heightOffset: Float = 0.0;
	@prop public var pathCheckTolerance: Float = 0.5;

	var path: Array<Vec4> = null;
	var index = 0;
	var isUpdating: Bool = false;
	var activeNavMesh: NavMesh = null;

	public function new() {
		super();
		notifyOnUpdate(initNavAgent);
	}
	
	function initNavAgent() {
		#if arm_navigation
		if(Navigation.active.navMeshes.length < 1 || !Navigation.active.navMeshes[0].ready) return;
		activeNavMesh = Navigation.active.navMeshes[0];
		removeUpdate(initNavAgent);
		#end
	}

	public function setPath(path: Array<Vec4>) {
		this.path = path;
		index = 1;
		if (!isUpdating) {
			notifyOnUpdate(update);
			isUpdating = true;
		}
	}

	public function stop() {
		if (isUpdating) {
			removeUpdate(update); 
			isUpdating = false;
		}
		path = null;
	}

	function update() {
		if (activeNavMesh == null || path == null || index >= path.length) {
			stop();
			return;
		}

		var currentLoc = object.transform.loc;
		var p = path[index];

		var dir = new Vec4().subvecs(p, currentLoc);

		var normal = activeNavMesh.getNavMeshNormal(currentLoc);
		normal.normalize();

		var normalDot = dir.dot(normal);

		dir.x -= normal.x * normalDot;
		dir.y -= normal.y * normalDot;
		dir.z -= normal.z * normalDot;

		var dist = dir.length();

		if (dist < pathCheckTolerance) {
			index++;

			if (index >= path.length) {
				stop();
				return;
			}

			p = path[index];

			dir.subvecs(p, currentLoc);

			normal = activeNavMesh.getNavMeshNormal(currentLoc);
			normal.normalize();

			normalDot = dir.dot(normal);

			dir.x -= normal.x * normalDot;
			dir.y -= normal.y * normalDot;
			dir.z -= normal.z * normalDot;

			dist = dir.length();
		}

		dir.normalize();

		var step = speed * Time.delta;
		if (step > dist) step = dist;

		var nextPos = new Vec4(
			currentLoc.x + dir.x * step,
			currentLoc.y + dir.y * step,
			currentLoc.z + dir.z * step
		);

		var projectedPos = activeNavMesh.moveAlong(currentLoc, nextPos);

		if (projectedPos == null) {
			stop();
			return;
		}

		normal = activeNavMesh.getNavMeshNormal(projectedPos);
		normal.normalize();

		object.transform.loc.set(
			projectedPos.x,
			projectedPos.y,
			projectedPos.z
		);

		var targetRot = new Quat().fromTo(new Vec4(0, 0, 1, 0), normal);

		var forward = new Vec4().setFrom(dir);

		var ndot = forward.dot(normal);

		forward.x -= normal.x * ndot;
		forward.y -= normal.y * ndot;
		forward.z -= normal.z * ndot;

		if (forward.length() > 0.0001) {
			forward.normalize();

			var xAxis = new Vec4(1, 0, 0, 0);
			xAxis.applyQuat(targetRot);

			var currForward = new Vec4().setFrom(xAxis);

			var twist = new Quat().fromTo(currForward, forward);

			targetRot = twist.mult(targetRot);
		}

		var currentRot = new Quat().setFrom(object.transform.rot);

		var t = turnDuration > 0 ? Time.delta / turnDuration : 1.0;

		if (t > 1.0) t = 1.0;

		object.transform.rot = new Quat().lerp(currentRot, targetRot, t);

		object.transform.buildMatrix();
	}
}