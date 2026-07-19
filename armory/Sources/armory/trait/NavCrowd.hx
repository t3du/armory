package armory.trait;

#if arm_navigation
import iron.math.Quat;
import iron.math.Vec4;
import armory.trait.navigation.Navigation;
#end
import iron.Trait;

class NavCrowd extends Trait {

	#if !arm_navigation
	public function new() { super(); }
	#else

	@prop
	public var navMeshId: String = 'NavMesh';

	// Position offset for the agent.
	@prop
	public var offset: Vec4 = new Vec4();

	// Radius of the agent.
	@prop
	public var radius: Float = 1.0;

	// Height of the agent.
	@prop
	public var height: Float = 1.0;

	// Should the agent turn.
	@prop 
	var turn: Bool = true;

	// Turn rate in range (0, 1).
	// 0 = No turn.
	// 1 = Instant turn without interpolation.
	@prop
	public var turnSpeed: Float = 0.1;

	// Threshold to avoid turning at low velocities which might cause jittering.
	@prop 
	public var turnVelocityThreshold: Float = 0.1;

	// Maximum speed of the crowd agent
	@prop
	public var maxSpeed: Float = 5.0;

	// Maximum acceleration of the agent
	@prop
	public var maxAcceleration: Float = 100.0;

	// How separated should the agents be. Effective when crowd separation flag is enabled.
	@prop
	public var separationWeight: Float = 1.0;

	// Distance to check for collisions. Typically should be greater than agent radius.
	@prop
	public var collisionQueryRange: Float = 2.0;

	// Anticipate turns and modify agent path
	@prop
	public var anticipateTurns: Bool = false;

	@prop
	public var obstacleAvoidance: Bool = false;

	@prop
	public var crowdSeparation: Bool = false;

	@prop
	public var optimizeVisibility: Bool = false;

	@prop
	public var optimizeTopology: Bool = false;

	public var agentReady(default, null) = false;
	var activeNavMesh: NavMesh = null;
	var agentID = -1;

	public function new() {
		super();

		notifyOnUpdate(addAgent);
		notifyOnRemove(removeAgent);
	}

	function addAgent() {

		activeNavMesh = Navigation.active.navMeshes.get(navMeshId);
		if(activeNavMesh == null || !activeNavMesh.ready) return;

		var flags: Int = 0;
		if(anticipateTurns) flags += 1;
		if(obstacleAvoidance) flags += 2;
		if(crowdSeparation) flags += 4;
		if(optimizeVisibility) flags += 8;
		if(optimizeTopology) flags += 16;

		var position = object.transform.world.getLoc();
		agentID = activeNavMesh.addCrowdAgent(this, position, radius, height, maxAcceleration, maxSpeed, flags, separationWeight, collisionQueryRange);

		notifyOnUpdate(updateCrowdAgent);
		removeUpdate(addAgent);
		agentReady = true;
	}

	public function crowdAgentMaxSpeed():Float {
	    if (!agentReady) return 0.0;
	    return activeNavMesh.crowdGetAgentMaxSpeed(agentID);
	}

	public function crowdAgentMaxAcceleration():Float {
	    if (!agentReady) return 0.0;
	    return activeNavMesh.crowdGetAgentMaxAcceleration(agentID);
	}

	public function crowdAgentSetMaxSpeed(speed:Float):Void {
		if (!agentReady) return;
		maxSpeed = speed;
		activeNavMesh.crowdSetAgentMaxSpeed(agentID, speed);
	}

	public function crowdAgentSetMaxAcceleration(acceleration:Float):Void {
		if (!agentReady) return;
		maxAcceleration = acceleration;
		activeNavMesh.crowdSetAgentMaxAcceleration(agentID, acceleration);
	}

	public function crowdAgentVelocity(): Vec4 {
		if(!agentReady) return null;

		return activeNavMesh.crowdGetAgentVelocity(agentID);
	}

	public function crowdAgentPosition(): Vec4 {
		if(!agentReady) return null;

		return activeNavMesh.crowdGetAgentPosition(agentID);
	}

	public function crowdAgentNextPath(): Vec4 {
		if(!agentReady) return null;

		return activeNavMesh.crowdGetAgentNextTargetPath(agentID);
	}

	public function crowdAgentPath(): Array<Vec4> {
		if(!agentReady) return null;

		return activeNavMesh.crowdGetCorners(agentID);
	}

	public function crowdAgentGoto(position: Vec4) {
		if(!agentReady) return;

		activeNavMesh.crowdAgentGoto(agentID, position);
	}

	public function crowdAgentTeleport(position: Vec4) {
		if(!agentReady) return;

		activeNavMesh.crowdAgentTeleport(agentID, position.sub(offset));
	}

	function removeAgent() {
		activeNavMesh.removeCrowdAgent(agentID);
	}

	function updateCrowdAgent() {
		if(!agentReady) return;
		var pos = activeNavMesh.crowdGetAgentPosition(agentID);
		pos.add(offset);
		object.transform.loc.setFrom(pos);
		if(turn) turnAgent();
		object.transform.buildMatrix();
	}

	function turnAgent() {
		var pos = activeNavMesh.crowdGetAgentPosition(agentID);
		var vel = activeNavMesh.crowdGetAgentVelocity(agentID);
		var normal = activeNavMesh.getNavMeshNormal(pos);
		var currentRot = new Quat().setFrom(object.transform.rot);

		var up = new Vec4(0, 0, 1, 0);
		up.applyQuat(currentRot);
		object.transform.rot = new Quat().fromTo(up, normal).mult(currentRot);

		vel.z = 0;
		if (vel.length() < turnVelocityThreshold) return;
		vel.normalize();

		var targetRotBase = new Quat().fromTo(new Vec4(1, 0, 0, 1), vel);
		var upVec = new Vec4(0, 0, 1, 0);
		upVec.applyQuat(targetRotBase);
		var targetRot = new Quat().fromTo(upVec, normal).mult(targetRotBase);

		object.transform.rot = new Quat().lerp(new Quat().setFrom(object.transform.rot), targetRot, turnSpeed);
	}
	#end
}