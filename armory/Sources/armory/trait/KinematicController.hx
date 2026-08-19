package armory.trait;

import iron.Trait;
import armory.trait.physics.bullet.KinematicCharacterController;
import armory.trait.physics.bullet.KinematicCharacterController.ControllerShape;
import iron.system.Input;
import iron.system.Input.Keyboard;
import iron.math.Vec4;

class KinematicController extends Trait {

	@prop
	public var mass:Float = 75.0;

	@prop
	public var speed:Float = 0.08;

	@prop
	public var jumpSpeed:Float = 10.0;

	@prop
	public var fallSpeed:Float = 55.0;

	@prop
	public var maxSlope:Float = 0.785398;

	@prop
	public var maxJumpHeight:Float = 5.0;

	@prop
	public var friction:Float = 0.8;

	var controller:KinematicCharacterController;
	var keyboard:Keyboard = Input.getKeyboard();
	var initComplete:Bool = false;
	var jumpV:Vec4 = new Vec4(0.0, 0.0, 8.0);
	var move:Vec4 = new Vec4();

	public function new() {
		super();
		iron.Scene.active.notifyOnInit(init);
		notifyOnUpdate(update);
	}

	function init() {
		controller = new KinematicCharacterController(mass, ControllerShape.Capsule);
		controller.notifyOnReady(onControllerReady);
		object.addTrait(controller);
	}

	function onControllerReady() {
		controller.setJumpSpeed(jumpSpeed);
		controller.setFallSpeed(fallSpeed);
		controller.setMaxSlope(maxSlope);
		controller.setMaxJumpHeight(maxJumpHeight);
		controller.setUpInterpolate(true);
		controller.setFriction(friction);

		initComplete = true;
	}

	function update() {
		if (!initComplete) return;

		move.set(0, 0, 0);

		if (keyboard.down("up") || keyboard.down("w")) move.y += 1;
		if (keyboard.down("down") || keyboard.down("s")) move.y -= 1;
		if (keyboard.down("left") || keyboard.down("a")) move.x -= 1;
		if (keyboard.down("right") || keyboard.down("d")) move.x += 1;

		if (move.length() > 0) {
			move.normalize();
			move.mult(speed);
		}

		if (keyboard.started("space")) {
			if (controller.canJump() && controller.onGround()) {
				#if js
				controller.jump();
				#elseif cpp
				jumpV.z = jumpSpeed;
				controller.jump(jumpV);
				#end
			}
		}

		controller.setWalkDirection(move);
	}
}