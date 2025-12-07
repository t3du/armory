package armory.trait;

import iron.Trait;
import iron.math.Vec4;
import iron.math.Quat;
import iron.system.Tween;

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

	var rotAnim: TAnim = null;
	var locAnim: TAnim = null;

	public var tickPos: Null<Void -> Void>;
	public var tickRot: Null<Void -> Void>;
    
    var activeNavMesh: NavMesh = null;

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
		if (rotAnim != null) { 
            Tween.stop(rotAnim); 
            rotAnim = null;
        }
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
		if (from < 0) from += Math.PI * 2;
		if (to < 0) to += Math.PI * 2;
		var delta = Math.abs(from - to);
		if (delta > Math.PI) to = Math.PI * 2 - delta;
		return to;
	}

	var orient = new Vec4();
    
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

		orient.subvecs(p, object.transform.loc).normalize;
		var targetAngle = Math.atan2(orient.y, orient.x) + Math.PI / 2;
        
		locAnim = Tween.to({ target: object.transform.loc, props: { x: p.x, y: p.y, z: p.z + heightOffset }, duration: dist / speed, tick: tickPos, done: function() {
            
            if (path == null) return; 
            
            locAnim = null; 
			index++;
            
			go(); 
		}});

		var q = new Quat();
		rotAnim = Tween.to({ target: object.transform, props: { rot: q.fromEuler(0, 0, targetAngle) }, tick: tickRot, duration: turnDuration});
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
		object.transform.buildMatrix();
	}
}