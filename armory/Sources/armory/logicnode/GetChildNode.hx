package armory.logicnode;

import iron.object.Object;
import iron.object.MeshObject;
import iron.object.CameraObject;
import iron.object.LightObject;
import iron.object.SpeakerObject;
import iron.object.DecalObject;
import iron.object.ProbeObject;
import iron.object.CurveObject;

class GetChildNode extends LogicNode {

	public var property0: String;
	public var property1: String;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function get(from: Int): Dynamic {
		var object: Object = inputs[0].get();
		if (object == null) return null;

		if (property0 != "By Type") {
			var childName: String = inputs[1].get();
			if (childName == null) return null;

			return switch (property0) {
				case "By Name": object.getChild(childName);
				case "Contains": contains(object, childName);
				case "Starts With": startsWith(object, childName);
				case "Ends With": endsWith(object, childName);
				default: null;
			}
		}

		return switch (property1) {
			case "MeshObject": object.getChildOfType(MeshObject);
			case "CameraObject": object.getChildOfType(CameraObject);
			case "LightObject": object.getChildOfType(LightObject);
			case "SpeakerObject": object.getChildOfType(SpeakerObject);
			case "DecalObject": object.getChildOfType(DecalObject);
			case "ProbeObject": object.getChildOfType(ProbeObject);
			case "CurveObject": object.getChildOfType(CurveObject);
			default: null;
		}
	}

	function contains(o: Object, name: String): Object {
		for (c in o.children) {
			if (c.name.indexOf(name) >= 0) return c;
		}
		return null;
	}

	function startsWith(o: Object, name: String): Object {
		for (c in o.children) {
			if (StringTools.startsWith(c.name, name)) return c;
		}
		return null;
	}

	function endsWith(o: Object, name: String): Object {
		for (c in o.children) {
			if (StringTools.endsWith(c.name, name)) return c;
		}
		return null;
	}
}