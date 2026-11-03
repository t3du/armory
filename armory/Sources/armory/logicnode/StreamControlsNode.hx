
package armory.logicnode;

import armory.network.StreamControls;

class StreamControlsNode extends LogicNode {

	var streamControls:StreamControls;

	public function new(tree:LogicTree) {
		super(tree);
		tree.notifyOnRemove(onRemove);
	}

	override function run(from:Int):Void {

		if (from == 1) {

			cleanup();
			runOutput(0);
			return;
		}

		cleanup();

		var stream:Dynamic = inputs[2].get();

		if (stream == null) {

			trace("StreamControlsNode: Media Stream is required.");
			return;
		}

		try {

			var title:String = inputs[3].get();

			var x:Int = inputs[4].get();
			var y:Int = inputs[5].get();

			var width:Int = inputs[6].get();
			var height:Int = inputs[7].get();

			var videoVisible:Bool = inputs[8].get();
			var audioEnabled:Bool = inputs[9].get();

			var panelStyle:String = inputs[10].get();
			var buttonStyle:String = inputs[11].get();
			var videoStyle:String = inputs[12].get();

			streamControls = new StreamControls(
				stream,
				title,
				x,
				y,
				width,
				height,
				videoVisible,
				audioEnabled,
				panelStyle,
				buttonStyle,
				videoStyle
			);

			streamControls.create();

			runOutput(0);

		}
		catch (error:Dynamic) {

			trace("StreamControlsNode: " + Std.string(error));

			cleanup();
		}
	}

	function onRemove():Void {
		cleanup();
	}

	function cleanup():Void {

		if (streamControls != null) {

			streamControls.dispose();
			streamControls = null;
		}
	}
}