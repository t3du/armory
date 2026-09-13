package armory.logicnode;

import iron.object.CameraObject;
import iron.format.avi.Writer;
import iron.format.avi.Data;
import haxe.io.BytesOutput;
import haxe.io.Bytes;
import kha.audio2.Audio;
import kha.audio2.Buffer;
import kha.internal.IntBox;
import kha.Color;

class WriteVideoNode extends LogicNode {

	var file: String;
	var camera: CameraObject;
	var renderTarget: kha.Image;

	var height: Int;
	var width: Int;

	var isRecording: Bool = false;
	var isProcessing: Bool = false;
	var rawFramesQueue: Array<RawFrame>;
	var encodedFrames: Array<Bytes>;
	var currentFrame: Int = 0;
	var totalFrames: Int = 0;
	var frameDuration: Float = 0.1;
	var lastFrameTime: Float = 0.0;

	var currentProcessingFrame: RawFrame = null;
	var currentRgb: Bytes = null;
	var processIndexY: Int = 0;
	var itemsPerUpdate: Int = 8;

	var audioSamplesArray: Array<Float>;
	var oldCallback: IntBox -> Buffer -> Void;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		if (from == 0) {
			if (isRecording || isProcessing) return;

			file = inputs[2].get();
			camera = inputs[3].get();
			width = inputs[4].get();
			height = inputs[5].get();
			frameDuration = inputs[11].get();

			renderTarget = kha.Image.createRenderTarget(width, height,
				kha.graphics4.TextureFormat.RGBA32,
				kha.graphics4.DepthStencilFormat.NoDepthAndStencil);

			rawFramesQueue = [];
			encodedFrames = [];
			currentFrame = 0;
			totalFrames = 0;
			lastFrameTime = iron.system.Time.time();

			audioSamplesArray = [];
			oldCallback = Audio.audioCallback;
			Audio.audioCallback = audioCallback;

			isRecording = true;
			tree.notifyOnRender(render);
			runOutput(0);
		}
		else if (from == 1) {
			if (!isRecording) return;

			isRecording = false;
			tree.removeRender(render);
			Audio.audioCallback = oldCallback;

			currentFrame = 0;
			isProcessing = true;
			iron.App.notifyOnUpdate(processQueueStep);
		}
	}

	function audioCallback(samples: IntBox, buffer: Buffer): Void {
		var start: Int = buffer.writeLocation;
		if (oldCallback != null) {
			oldCallback(samples, buffer);
		}
		var volume: Float = inputs[12].get();
		if (volume == null || volume <= 0.0) return;

		var count: Int = samples.value;
		for (i in 0...count) {
			var idx: Int = (start + i) % buffer.size;
			var fVal: Float = buffer.data.get(idx) * volume;
			if (fVal < -1.0) fVal = -1.0;
			if (fVal > 1.0) fVal = 1.0;
			audioSamplesArray.push(fVal);
		}
	}

	function render(g: kha.graphics4.Graphics) {
		if (!isRecording) return;

		var currentTime = iron.system.Time.time();
		if (currentTime - lastFrameTime < frameDuration) return;
		lastFrameTime = currentTime;

		var ready = false;
		final sceneCam = iron.Scene.active.camera;
		final oldRT = camera.renderTarget;

		iron.Scene.active.camera = camera;
		camera.renderTarget = renderTarget;

		camera.renderFrame(g);

		var tex = camera.renderTarget;

		camera.renderTarget = oldRT;
		iron.Scene.active.camera = sceneCam;

		if (inputs[10].get()){

			tex = kha.Image.createRenderTarget(width, height,
				kha.graphics4.TextureFormat.RGBA32,
				kha.graphics4.DepthStencilFormat.NoDepthAndStencil);

			tex.g2.begin(true, Color.Transparent);

			tex.g2.color = Color.White;
			tex.g2.drawScaledImage(renderTarget, 0, 0, width, height);

			var scl = width / iron.App.w();

			if (kha.Image.renderTargetsInvertedY()){
				tex.g2.scale(scl, -scl);
				tex.g2.translate(0, height);
			}
			else
				tex.g2.scale(scl, scl);

			for (f in @:privateAccess iron.App.traitRenders2D){
				f(tex.g2);
			}

			tex.g2.end();

		}

		var pixels = tex.getPixels();

		for (i in 0...pixels.length)
			if (pixels.get(i) != 0){ ready = true; break; }

		if (ready) {
			rawFramesQueue.push({
				pixels: pixels,
				texWidth: tex.width,
				texHeight: tex.height
			});
			totalFrames++;
		}
	}

	function processQueueStep() {
		var tx = inputs[6].get();
		var ty = inputs[7].get();
		var tw = inputs[8].get();
		var th = inputs[9].get();

		if (currentProcessingFrame == null) {
			if (rawFramesQueue.length > 0) {
				currentProcessingFrame = rawFramesQueue.shift();
				currentRgb = haxe.io.Bytes.alloc(tw * th * 4);
				processIndexY = ty;
				currentFrame++;
			} else {
				iron.App.removeUpdate(processQueueStep);
				isProcessing = false;
				saveVideo();
				runOutput(1);
				return;
			}
		}

		var endY = Std.int(Math.min(processIndexY + itemsPerUpdate, ty + th));

		for (j in processIndexY...endY) {
			for (i in tx...tx + tw) {
				var k = j * currentProcessingFrame.texWidth + i;
				var m = (j - ty) * tw + i - tx;

				#if kha_krom
				var l = k;
				#elseif kha_html5
				var l = (currentProcessingFrame.texHeight - j) * currentProcessingFrame.texWidth + i;
				#end

				currentRgb.set(m * 4 + 0, currentProcessingFrame.pixels.get(l * 4 + 3));
				currentRgb.set(m * 4 + 1, currentProcessingFrame.pixels.get(l * 4 + 0));
				currentRgb.set(m * 4 + 2, currentProcessingFrame.pixels.get(l * 4 + 1));
				currentRgb.set(m * 4 + 3, currentProcessingFrame.pixels.get(l * 4 + 2));
			}
		}

		processIndexY = endY;

		if (processIndexY >= ty + th) {
			var jpgOut = new BytesOutput();
			var writer = new iron.format.jpg.Writer(jpgOut);
			writer.write({width: tw, height: th, quality: 80, pixels: currentRgb});

			encodedFrames.push(jpgOut.getBytes());
			currentProcessingFrame = null;
			currentRgb = null;
		}
	}

	function saveVideo() {
		if (encodedFrames.length == 0) return;

		var tw = inputs[8].get();
		var th = inputs[9].get();
		var fps = Math.round(1.0 / frameDuration);
		if (fps <= 0) fps = 10;

		var sampleRate = Audio.samplesPerSecond;
		var channels = 2;
		var maxSamples = Std.int((totalFrames / fps) * sampleRate * channels);

		var finalAudio = audioSamplesArray;
		if (audioSamplesArray.length > maxSamples) {
			finalAudio = audioSamplesArray.slice(0, maxSamples);
		}

		var out = new BytesOutput();
		var writer = new iron.format.avi.Writer(out);

		var data: AviData = {
			width: tw,
			height: th,
			fps: fps,
			frames: encodedFrames,
			audioSamples: finalAudio,
			sampleRate: sampleRate,
			channels: channels
		};

		writer.write(data);

		#if kha_krom
		Krom.fileSaveBytes(Krom.getFilesLocation() + "/" + file, out.getBytes().getData());

		#elseif kha_html5
		var blob = new js.html.Blob([out.getBytes().getData()], {type: "application"});
		var url = js.html.URL.createObjectURL(blob);
		var a = cast(js.Browser.document.createElement("a"), js.html.AnchorElement);
		a.href = file;
		a.download = file;
		a.click();
		js.html.URL.revokeObjectURL(url);
		#end
	}

	override function get(from: Int): Dynamic {
		return from == 2 ? totalFrames : currentFrame;
	}
}

typedef RawFrame = {
	var pixels: haxe.io.Bytes;
	var texWidth: Int;
	var texHeight: Int;
}
