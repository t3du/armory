package armory.logicnode;

import iron.data.MaterialData;

class MaterialNode extends LogicNode {

	public var property0: String;
	public var value: MaterialData = null;

	public function new(tree: LogicTree) {
		super(tree);

		iron.Scene.active.notifyOnInit(function() {
			get(0);
		});
	}

	override function get(from: Int): Dynamic {
		if (property0 != null && value == null) {
			var currentSceneName = iron.Scene.active.raw.name;

			iron.data.Data.getSceneRaw(currentSceneName, function(currentFormat: iron.data.SceneFormat.TSceneFormat) {
				var foundInCurrent = false;

				if (currentFormat.material_datas != null) {
					for (matData in currentFormat.material_datas) {
						if (matData.name == property0) {
							foundInCurrent = true;
							iron.data.Data.getMaterial(currentSceneName, property0, function(mat: MaterialData) {
								value = mat;
							});
							break;
						}
					}
				}

				if (!foundInCurrent) {
					for (sceneName in armory.system.Starter.scenes) {
						if (sceneName == currentSceneName) continue;

						iron.data.Data.getSceneRaw(sceneName, function(sceneFormat: iron.data.SceneFormat.TSceneFormat) {
							if (sceneFormat.material_datas != null) {
								for (matData in sceneFormat.material_datas) {
									if (matData.name == property0) {
										iron.data.Data.getMaterial(sceneName, property0, function(mat: MaterialData) {
											value = mat;
										});
										break;
									}
								}
							}
						});
						if (value != null) break;
					}
				}
			});
		}

		return value;
	}

	override function set(value: Dynamic) {
		this.value = value;
	}
}