package armory.trait.internal;

import kha.Image;
import kha.Blob;

import iron.Trait;
import iron.format.avi.Reader;
import iron.object.MeshObject;
import haxe.io.Bytes;

/**
	Replaces the diffuse texture of the first material of the trait's object
	with a video texture.

	@see https://github.com/armory3d/armory_examples/tree/master/material_movie
**/
class MovieTexture extends Trait {

	/**
		Caches all render targets used by this trait for re-use when having
		multiple videos of the same size. The lookup only takes place on trait
		initialization.

		Map layout: `[width => [height => image]]`
	**/
	static var frameCache: Map<String, Map<Int, Image>> = new Map();
	static var videoFrames: Map<String, Array<Bytes>> = new Map();
	static var videoFps: Map<String, Float> = new Map();
	static var loadingVideos: Map<String, Bool> = new Map();
	static var waitingTraits: Map<String, Array<MovieTexture>> = new Map();

	var image: Image;

	var videoName: String;
	var materialName: String;
	var textureName: String;
	var startFrame: Int;
	var endFrame: Int;
	var loop: Bool;
	var offset: Int;
	var currentFrame: Int;
	var displayedFrame: Int = -1;
	var frameTime: Float = 0.0;
	var fps: Float = 10.0;
	var isDecoding = false;

	public function new(videoName: String, materialName: String, textureName: String, startFrame: Int, endFrame: Int, loop: Bool, offset: Int) {
		super();

		this.videoName = videoName;
		this.materialName = materialName;
		this.textureName = textureName;
		this.startFrame = startFrame;
		this.endFrame = endFrame;
		this.loop = loop;
		this.offset = offset;
		this.currentFrame = startFrame + offset;

		notifyOnInit(init);
	}

	function init() {
		currentFrame = startFrame + offset;
		displayedFrame = -1;
		frameTime = 0.0;
		image = null;
		isDecoding = false;
		var waiting = waitingTraits[videoName];
		if (waiting == null) waitingTraits[videoName] = waiting = [];
		waiting.push(this);
		if (videoFrames.exists(videoName)) {
			ready();
			return;
		}
		if (loadingVideos.exists(videoName)) return;
		loadingVideos[videoName] = true;
		iron.data.Data.getBlob(videoName, function(blob: Blob) {
			var data = new Reader(new haxe.io.BytesInput(blob.bytes)).read();
			if (data == null) return;
			videoFrames[videoName] = data.frames;
			videoFps[videoName] = data.fps > 0 ? data.fps : 10.0;
			var traits = waitingTraits[videoName];
			if (traits != null) for (trait in traits) trait.ready();
			waitingTraits.remove(videoName);
		});
	}

	function render(g: kha.graphics2.Graphics) {
		if (currentFrame < startFrame || currentFrame > endFrame) {
			if (loop) currentFrame = startFrame + offset;
			else return;
		}
		if (currentFrame >= videoFrames[videoName].length) {
			if (loop) currentFrame = startFrame + offset;
			else return;
		}
		if (currentImageNeedsUpdate()) loadFrame(currentFrame);
		if (image == null) return;
		frameTime += iron.system.Time.delta;
		fps = videoFps[videoName] != null ? videoFps[videoName] : 10.0;
		if (displayedFrame == currentFrame && frameTime >= 1.0 / fps) {
			currentFrame++;
			frameTime = 0.0;
			if (currentFrame > endFrame) {
				if (loop) {
					currentFrame = startFrame + offset;
					frameTime = 0.0;
				}
				else currentFrame = endFrame;
			}
		}
	}

	function ready() {
		if (videoFrames[videoName] == null || videoFrames[videoName].length == 0) return;
		applyTexture();
		notifyOnRender2D(render);
	}

	function currentImageNeedsUpdate(): Bool {
		return displayedFrame != currentFrame || image == null || !frameCache.exists(videoName) || frameCache[videoName][currentFrame] == null;
	}

	function loadFrame(frame: Int) {
		if (isDecoding) return;
		var bytes = videoFrames[videoName][frame];
		if (bytes == null) return;
		var cached = frameCache[videoName];
		if (cached == null) frameCache[videoName] = cached = new Map();
		if (cached[frame] != null) {
			image = cached[frame];
			displayedFrame = frame;
			applyTexture();
			return;
		}
		isDecoding = true;
		Image.fromEncodedBytes(bytes, "jpg", function(decoded: Image) {
			#if kha_krom
			var pixels = decoded.getPixels();
			image = Image.fromBytes(pixels, decoded.width, decoded.height, kha.graphics4.TextureFormat.RGBA32);
			decoded.unload();
			#else
			image = decoded;
			#end
			cached[frame] = image;
			displayedFrame = frame;
			isDecoding = false;
			applyTexture();
		}, function(error: String) {
			isDecoding = false;
		}, true);
	}

	function applyTexture() {
		var mesh = cast(object, MeshObject);
		for (materialIndex in 0...mesh.materials.length) {
			var material = mesh.materials[materialIndex];
			if (material.raw.name != materialName) continue;
			for (contextIndex in 0...material.contexts.length) {
				var context = material.contexts[contextIndex];
				for (textureIndex in 0...context.raw.bind_textures.length) {
					var name = context.raw.bind_textures[textureIndex].name;
					if (name == textureName || normalize(name) == normalize(textureName)) {
						context.textures[textureIndex] = image;
					}
				}
			}
		}
	}

	function normalize(name: String): String {
		return StringTools.replace(name, " ", "");
	}
}
