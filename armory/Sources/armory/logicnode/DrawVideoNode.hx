package armory.logicnode;

import iron.math.Vec4;
import iron.format.avi.Reader;
import kha.Color;
import kha.Blob;
import kha.Image;
import kha.Sound;
import kha.audio1.AudioChannel;
import haxe.io.Bytes;
import armory.renderpath.RenderToTexture;

class DrawVideoNode extends LogicNode {
	var rawFrames: Array<Bytes> = [];
	var currentImage: Image;
	var sound: Sound;
	var channel: AudioChannel;
	var lastVideoName = "";
	var currentFrame: Int = 0;
	var videoFps: Float = 10.0;
	var frameTime: Float = 0.0;
	var displayedFrame: Int = -1;
	var totalFrames: Int = 0;
	var isDecoding = false;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		RenderToTexture.ensure2DContext("DrawVideoNode");

		final videoName: String = inputs[1].get();
		final colorVec: Vec4 = inputs[2].get();
		final anchorH: Int = inputs[3].get();
		final anchorV: Int = inputs[4].get();
		final x: Float = inputs[5].get();
		final y: Float = inputs[6].get();
		final width: Float = inputs[7].get();
		final height: Float = inputs[8].get();
		var sx: Float = inputs[9].get();
		var sy: Float = inputs[10].get();
		var swidth: Float = inputs[11].get();
		var sheight: Float = inputs[12].get();
		final angle: Float = inputs[13].get();
		final startFrame: Int = inputs[14].get();
		final endFrame: Int = inputs[15].get();
		final volume: Float = inputs[16].get();
		final loop: Bool = inputs[17].get();

		final drawx = x - 0.5 * width * anchorH;
		final drawy = y - 0.5 * height * anchorV;

		RenderToTexture.g.rotate(angle, x, y);

		if (videoName != lastVideoName) {
			lastVideoName = videoName;
			currentFrame = startFrame;
			displayedFrame = -1;
			rawFrames = [];
			frameTime = 0.0;
			if (currentImage != null) {
				currentImage.unload();
				currentImage = null;
			}

			iron.data.Data.getBlob(videoName, (blob: Blob) -> {
				var input = new haxe.io.BytesInput(blob.bytes);
				var reader = new Reader(input);
				var aviData = reader.read();

				if (aviData == null) return;

				rawFrames = aviData.frames;
				totalFrames = rawFrames.length;
				videoFps = aviData.fps > 0 ? aviData.fps : 10.0;

				if (aviData.audioSamples.length > 0) {
					sound = new Sound();
					sound.channels = aviData.channels > 0 ? aviData.channels : 2;
					sound.sampleRate = aviData.sampleRate > 0 ? aviData.sampleRate : 44100;
					sound.length = aviData.audioSamples.length / sound.channels / sound.sampleRate;
					sound.uncompressedData = new kha.arrays.Float32Array(aviData.audioSamples.length);
					for (i in 0...aviData.audioSamples.length) {
						sound.uncompressedData[i] = aviData.audioSamples[i];
					}
				}

				if (sound != null && volume > 0.0 && channel == null) {
					channel = kha.audio1.Audio.play(sound, loop);
					if (channel != null) channel.volume = volume;
				}
			});
		}

		if (channel != null) channel.volume = volume;

		if (rawFrames.length == 0 || currentFrame >= rawFrames.length) {
			runOutput(0);
			return;
		}

		if (currentFrame != displayedFrame && !isDecoding && rawFrames[currentFrame] != null) {
			isDecoding = true;
			var frameToLoad = currentFrame;
			Image.fromEncodedBytes(rawFrames[frameToLoad], "jpg", (img: Image) -> {
			#if kha_krom
				var pixels = img.getPixels();
				var uploadImage = Image.fromBytes(pixels, img.width, img.height, kha.graphics4.TextureFormat.RGBA32);
				img.unload();
			#else
				var uploadImage = img;
			#end
				var oldImg = currentImage;
				currentImage = uploadImage;
				displayedFrame = frameToLoad;
				isDecoding = false;
				if (oldImg != null) {
					oldImg.unload();
				}
			}, (err: String) -> {
				trace("DrawVideoNode ERROR" + frameToLoad + ": " + err);
				isDecoding = false;
			}, true);
		}

		if (currentImage != null) {
			var drawSWidth = (swidth <= 0) ? currentImage.width : swidth;
			var drawSHeight = (sheight <= 0) ? currentImage.height : sheight;

			RenderToTexture.g.color = Color.fromFloats(colorVec.x, colorVec.y, colorVec.z, colorVec.w);
			RenderToTexture.g.drawScaledSubImage(currentImage, sx, sy, drawSWidth, drawSHeight, drawx, drawy, width, height);
			if (displayedFrame == currentFrame) {
				frameTime += iron.system.Time.delta;
				var frameStep = 1.0 / videoFps;
				if (frameTime >= frameStep) {
					var framesToAdvance = Std.int(frameTime / frameStep);
					if (framesToAdvance > 1) framesToAdvance = 1;
					currentFrame += framesToAdvance;
					frameTime -= framesToAdvance * frameStep;
				}
			}
		}
		RenderToTexture.g.rotate(-angle, x, y);

		var maxFrame: Int = (endFrame == -1) ? totalFrames : endFrame;
		if (currentFrame >= maxFrame) {
			if (loop) {
				currentFrame = startFrame;
				frameTime = 0.0;
				if (channel != null && volume > 0.0) {
					channel.stop();
					channel = kha.audio1.Audio.play(sound, loop);
				}
			} else {
				currentFrame = maxFrame - 1;
			}
		}

		runOutput(0);
	}

	override function get(from: Int): Dynamic {
		return from == 1 ? totalFrames : currentFrame;
	}
}