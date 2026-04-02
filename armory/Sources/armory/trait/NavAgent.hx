package armory.trait;

import iron.Trait;
import iron.math.Vec4;
import iron.math.Quat;
import iron.system.Tween;
import iron.system.Time;

#if arm_navigation
import armory.trait.navigation.Navigation;
#end

class NavAgent extends Trait {

	@prop
	public var speed: Float = 5;
	@prop
	public var turnDuration: Float = 0.4;
	@prop
	public var heightOffset: Float = 0.0;
    
    @prop
    public var pathCheckTolerance: Float = 0.5;

	var path: Array<Vec4> = null;
	var index = 0;
    var isUpdating: Bool = false;

	var locAnim: TAnim = null;

	public var tickPos: Null<Void -> Void>;
	public var tickRot: Null<Void -> Void>;
    
    var activeNavMesh: NavMesh = null;

    var qNormal = new Quat();
    var orient = new Vec4();
    var dir = new Quat();
    var currentAngle: Float = 0.0;

	public function new() {
		super();
		notifyOnRemove(stopTween);
        notifyOnInit(initNavAgent);
	}
    
    function initNavAgent() {
        #if arm_navigation
		if (Navigation.active.navMeshes.length > 0) {
			activeNavMesh = Navigation.active.navMeshes[0];
		}
        #end
        currentAngle = object.transform.rot.getEuler().z;
	}

	public function setPath(path: Array<Vec4>) {
		stopTween();

		this.path = path;
		index = 1;
        
        if (!isUpdating) {
            notifyOnUpdate(update);
            isUpdating = true;
        }
		
		go();
	}

	function stopTween() {
		if (locAnim != null) { 
            Tween.stop(locAnim); 
            locAnim = null;
        }
	}

	public function stop() {
		stopTween();
        
		if (isUpdating) {
            removeUpdate(update); 
            isUpdating = false;
        }
		path = null;
	}

    function shortAngle(from: Float, to: Float): Float {
        var delta = to - from;
        while (delta < -Math.PI) delta += Math.PI * 2;
        while (delta > Math.PI) delta -= Math.PI * 2;
        return from + delta;
    }

	function go() {
		if (path == null || index >= path.length) {
            stop(); 
            return;
        }
        
        if (!validateAndRecalculatePath()) {
            return;
        }
        
		var p = path[index];
		var dist = Vec4.distance(object.transform.loc, p);

		locAnim = Tween.to({ target: object.transform.loc, props: { x: p.x, y: p.y, z: p.z + heightOffset }, duration: dist / speed, tick: tickPos, done: function() {
            if (path == null) return; 
            locAnim = null; 
			index++;
			go(); 
		}});
	}

    function validateAndRecalculatePath(): Bool {
        #if arm_navigation
        if (activeNavMesh == null || !activeNavMesh.ready || path == null || path.length < index + 1) return true;
        
        var currentPosition = object.transform.world.getLoc();
        var nextCorner = path[index];
        var destination = path[path.length - 1];

        var projectedPosition = activeNavMesh.moveAlong(currentPosition, nextCorner);

        if (projectedPosition.distanceTo(nextCorner) > pathCheckTolerance) {
            stopTween(); 
            activeNavMesh.findPath(currentPosition, destination, function(newPath: Array<Vec4>) {
                Tween.timer(0.0, function() { 
                    if (newPath.length > 1) {
                        setPath(newPath); 
                    } else {
                        stop(); 
                    }
                });
            });
            return false;
        }
        #end
        return true;
    }

	function update() {
        if (path != null && index < path.length) {
            var p = path[index];
            orient.subvecs(p, object.transform.loc).normalize();
            
            var targetA = Math.atan2(orient.y, orient.x);
            var nextA = shortAngle(currentAngle, targetA);
            
            var lerpFactor = turnDuration > 0 ? (1.0 / turnDuration) * Time.delta : 1.0;
            currentAngle = currentAngle + (nextA - currentAngle) * Math.min(lerpFactor, 1.0);
            
            dir.fromEuler(0, 0, currentAngle);

            #if arm_navigation
            if (activeNavMesh != null) {
                var normal = activeNavMesh.getNavMeshNormal(object.transform.loc);
                qNormal.fromTo(new Vec4(0, 0, 1), normal);
                object.transform.rot.multquats(qNormal, dir);
            } else {
                object.transform.rot.setFrom(dir);
            }
            #else
            object.transform.rot.setFrom(dir);
            #end
            
            if (tickRot != null) tickRot();
        }

		object.transform.buildMatrix();
	}
}