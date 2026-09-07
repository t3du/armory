package armory.trait;

import iron.Trait;
import iron.system.Input;
import iron.math.Vec4;
import iron.math.RayCaster;
import iron.Scene;
import iron.object.Object;
import armory.trait.physics.bullet.PhysicsWorld;
import armory.trait.physics.bullet.SoftBody;

class SoftBodyDrag extends Trait {

#if (!arm_bullet || !arm_physics_soft)
	public function new() {
		super();
	}
#else

	var pickedBody: SoftBody = null;
	var nodeIndex: Int = -1;
	var pickDist: Float;
	
	var rayFrom = new Vec4();
	var rayTo = new Vec4();

	public function new() {
		super();
		notifyOnUpdate(update);
	}

	function update() {
		var physics = PhysicsWorld.active;
		if (physics == null) return;
		var mouse = Input.getMouse();

		if (mouse.started()) {
			setRays();
			var hit = physics.rayCast(rayFrom, rayTo);
			
			if (hit != null) {
				var mySB = object.getTrait(SoftBody);

				if (mySB != null && mySB.ready) {
					pickedBody = mySB;
					nodeIndex = getClosestNode(hit.pos);
					
					#if js
					var node = pickedBody.body.get_m_nodes().at(nodeIndex);
					var p = node.get_m_x();
					var px = p.x(); var py = p.y(); var pz = p.z();
					#else
					var node = pickedBody.body.m_nodes.at(nodeIndex);
					var p = node.m_x;
					var px = p.x(); var py = p.y(); var pz = p.z();
					#end

					var dx = px - hit.pos.x;
					var dy = py - hit.pos.y;
					var dz = pz - hit.pos.z;
					var distSq = dx * dx + dy * dy + dz * dz;

					if (distSq < 1.0) {
						var camLoc = Scene.active.camera.transform.world.getLoc();
						var cdx = hit.pos.x - camLoc.x;
						var cdy = hit.pos.y - camLoc.y;
						var cdz = hit.pos.z - camLoc.z;
						pickDist = Math.sqrt(cdx * cdx + cdy * cdy + cdz * cdz);
						
						setNodeInverseMass(0.0);
						pickedBody.body.setActivationState(4);
						Input.occupied = true;
					} else {
						pickedBody = null;
						nodeIndex = -1;
					}
				}
			}
		}

		else if (mouse.released() && pickedBody != null) {
			setNodeInverseMass(1.0);
			pickedBody.body.setActivationState(1);
			pickedBody = null;
			nodeIndex = -1;
			Input.occupied = false;
		}

		else if (mouse.down() && pickedBody != null) {
			setRays();
			
			var vx = rayTo.x - rayFrom.x;
			var vy = rayTo.y - rayFrom.y;
			var vz = rayTo.z - rayFrom.z;
			var mag = Math.sqrt(vx * vx + vy * vy + vz * vz);
			
			var tx = rayFrom.x + (vx / mag) * pickDist;
			var ty = rayFrom.y + (vy / mag) * pickDist;
			var tz = rayFrom.z + (vz / mag) * pickDist;

			#if js
			var node = pickedBody.body.get_m_nodes().at(nodeIndex);
			var nodePos = node.get_m_x();
			#else
			var node = pickedBody.body.m_nodes.at(nodeIndex);
			var nodePos = node.m_x;
			#end

			nodePos.setValue(tx, ty, tz);
			pickedBody.body.setActivationState(4);
		}
	}

	function setNodeInverseMass(im: Float) {
		if (pickedBody == null || nodeIndex == -1) return;
		#if js
		var node = pickedBody.body.get_m_nodes().at(nodeIndex);
		untyped node.m_im = im;
		#else
		var node = pickedBody.body.m_nodes.at(nodeIndex);
		node.m_im = im;
		#end
	}

	function getClosestNode(hit: Vec4): Int {
		#if js
		var nodes = pickedBody.body.get_m_nodes();
		#else
		var nodes = pickedBody.body.m_nodes;
		#end
		var closest = 0;
		var minDist = 1e10;
		for (i in 0...nodes.size()) {
			var n = nodes.at(i);
			#if js
			var p = n.get_m_x();
			var px = p.x(); var py = p.y(); var pz = p.z();
			#else
			var p = n.m_x;
			var px = p.x(); var py = p.y(); var pz = p.z();
			#end
			var dx = px - hit.x;
			var dy = py - hit.y;
			var dz = pz - hit.z;
			var d = dx * dx + dy * dy + dz * dz;
			if (d < minDist) { minDist = d; closest = i; }
		}
		return closest;
	}

	function setRays() {
		var mouse = Input.getMouse();
		var camera = Scene.active.camera;
		var loc = camera.transform.world.getLoc();
		rayFrom.set(loc.x, loc.y, loc.z);
		var temp = new Vec4();
		RayCaster.getDirection(temp, rayTo, mouse.x, mouse.y, camera);
	}
#end
}