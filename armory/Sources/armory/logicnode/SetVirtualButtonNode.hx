package armory.logicnode;

class SetVirtualButtonNode extends LogicNode {

	public var property0: String;
	public var property1: String;
	public var property2: String;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		switch (property0) {
		case "Keyboard":
			var keyboard = iron.system.Input.getKeyboard();
			keyboard.setVirtual(property1, property2);
		case "Mouse":
			var mouse = iron.system.Input.getMouse();
			mouse.setVirtual(property1, property2);
		case "Gamepad":
			var gamepad = iron.system.Input.getGamepad(0);
			if (gamepad != null) {
				gamepad.setVirtual(property1, property2);
			}
		}

		runOutput(0);
	}
}