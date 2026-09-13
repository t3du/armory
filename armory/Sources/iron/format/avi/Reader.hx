package iron.format.avi;

import haxe.io.BytesInput;
import haxe.io.Bytes;
import iron.format.avi.Data;

class Reader {

	var input: BytesInput;

	public function new(input: BytesInput) {
		this.input = input;
	}

	public function read(): AviData {
		var width: Int = 0;
		var height: Int = 0;
		var fps: Float = 10.0;
		var frames: Array<Bytes> = [];
		var audioSamples: Array<Float> = [];
		var sampleRate: Int = 44100;
		var channels: Int = 2;

		var riff = input.readString(4);
		if (riff != "RIFF") return null;

		var fileSize = input.readInt32();
		var avi = input.readString(4);
		if (avi != "AVI ") return null;

		while (input.position < input.length) {
			if (input.position + 8 > input.length) break;
			var id = input.readString(4);
			var size = input.readInt32();

			if (id == "LIST") {
				var type = input.readString(4);
				if (type == "hdrl" || type == "strl") {
					continue;
				} else if (type == "movi") {
					var moviEnd = input.position + size - 4;
					while (input.position < moviEnd) {
						var chunkId = input.readString(4);
						var chunkSize = input.readInt32();

						if (chunkId == "00dc") {
							var frameBytes = input.read(chunkSize);
							frames.push(frameBytes);
							if (chunkSize % 2 != 0) input.readByte();
						} else if (chunkId == "01wb") {
							var numShorts = Std.int(chunkSize / 2);
							for (s in 0...numShorts) {
								var sampleInt = input.readInt16();
								audioSamples.push(sampleInt / 32767.0);
							}
							if (chunkSize % 2 != 0) input.readByte();
						} else {
							input.position += chunkSize + (chunkSize % 2);
						}
					}
				} else {
					input.position += size - 4;
				}
			} else if (id == "avih") {
				var microSecPerFrame = input.readInt32();
				if (microSecPerFrame > 0) fps = 1000000.0 / microSecPerFrame;
				input.position += size - 4;
			} else if (id == "strh") {
				var type = input.readString(4);
				if (type == "vids") {
					input.position += size - 4;
				} else if (type == "auds") {
					input.position += size - 4;
				} else {
					input.position += size - 4;
				}
			} else if (id == "strf") {
				if (size == 40) {
					var biSize = input.readInt32();
					width = input.readInt32();
					height = input.readInt32();
					input.position += size - 12;
				} else if (size == 16) {
					var wFormatTag = input.readInt16();
					channels = input.readInt16();
					sampleRate = input.readInt32();
					input.position += size - 8;
				} else {
					input.position += size;
				}
			} else {
				input.position += size + (size % 2);
			}
		}

		return {
			width: width,
			height: height,
			fps: fps,
			frames: frames,
			audioSamples: audioSamples,
			sampleRate: sampleRate,
			channels: channels
		};
	}

}