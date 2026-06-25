package armory.logicnode;

import iron.data.SceneFormat.TSceneFormat;
import iron.data.Data;
import iron.object.Object;
import iron.object.MeshObject;
import iron.Scene;

class AddParticleToObjectNode extends LogicNode {

	public var property0: String;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		#if arm_gpu_particles

		if (property0 == 'Scene Active'){
			var objFrom: Object = inputs[1].get();
			var slot: Int = inputs[2].get();
			var objTo: Object = inputs[3].get();

			if (objFrom == null || objTo == null) return;

			var mobjFrom = cast(objFrom, MeshObject);

			var psys = mobjFrom.particleSystems != null ? mobjFrom.particleSystems[slot] :
				mobjFrom.particleOwner != null && mobjFrom.particleOwner.particleSystems != null ? mobjFrom.particleOwner.particleSystems[slot] : null;

			if (psys == null) return;

			var mobjTo = cast(objTo, MeshObject);

			mobjTo.setupParticleSystem(Scene.active.raw.name, {name: 'ArmPS', seed: 0, particle: @:privateAccess psys.r.name});

			mobjTo.render_emitter = inputs[4].get();

			Scene.active.spawnObject(psys.data.raw.instance_object, null, function(o: Object) {
				if (o != null) {
					var c: MeshObject = cast o;
					if (mobjTo.particleChildren == null) mobjTo.particleChildren = [];
					mobjTo.particleChildren.push(c);
					c.particleOwner = mobjTo;
					c.particleIndex = mobjTo.particleChildren.length - 1;
				}
			});

			var oslot: Int = mobjTo.particleSystems.length-1;
			var opsys = mobjTo.particleSystems[oslot];
			@:privateAccess opsys.setupGeomGpu(mobjTo.particleChildren[oslot]);

		} else {
			var sceneName: String = inputs[1].get();
			var objectName: String = inputs[2].get();
			var slot: Int = inputs[3].get();

			var mobjTo: Object = inputs[4].get();
			var mobjTo = cast(mobjTo, MeshObject);

			#if arm_json
				sceneName += ".json";
			#elseif arm_compress
				sceneName += ".lz4";
			#end

			Data.getSceneRaw(sceneName, (rawScene: TSceneFormat) -> {

				for (obj in rawScene.objects) {
					if (obj.name == objectName) {
						mobjTo.setupParticleSystem(sceneName, obj.particle_refs[slot]);
						mobjTo.render_emitter = inputs[5].get();

						for (i => ps in rawScene.particle_datas)
							if (obj.particle_refs[slot].particle == ps.name){
								slot = i;
								break;
							}

						Scene.active.spawnObject(rawScene.particle_datas[slot].instance_object, null, function(o: Object) {
							if (o != null) {
								var c: MeshObject = cast o;
								if (mobjTo.particleChildren == null) mobjTo.particleChildren = [];
								mobjTo.particleChildren.push(c);
								c.particleOwner = mobjTo;
								c.particleIndex = mobjTo.particleChildren.length - 1;
							}
						}, true, rawScene);

						var oslot: Int = mobjTo.particleSystems.length-1;
						var opsys = mobjTo.particleSystems[oslot];
						@:privateAccess opsys.setupGeomGpu(mobjTo.particleChildren[oslot]);

						break;
					}
				}

			});

		}

		#end

		runOutput(0);
	}
}
