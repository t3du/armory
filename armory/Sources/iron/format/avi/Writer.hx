package iron.format.avi;

import haxe.io.BytesOutput;
import iron.format.avi.Data;

class Writer {

	var output: BytesOutput;

	public function new(output: BytesOutput) {
		this.output = output;
	}

	public function write(data: AviData) {
		var tw = data.width;
		var th = data.height;
		var fps: Float = data.fps <= 0 ? 10.0 : data.fps;
		var fpsScale = 1000;
		var fpsRate = Std.int(Math.round(fps * fpsScale));
		var numFrames = data.frames.length;

		var hasAudio = data.audioSamples != null && data.audioSamples.length > 0;
		var sampleRate = data.sampleRate <= 0 ? 44100 : data.sampleRate;
		var channels = data.channels <= 0 ? 2 : data.channels;
		var bitsPerSample = 16;
		var bytesPerSample = Std.int(bitsPerSample / 8);

		var samplesPerFrame = Std.int(sampleRate / fps);
		var audioBlockSizePerFrame = hasAudio ? samplesPerFrame * channels * bytesPerSample : 0;

		var totalVideoBytes = 0;
		for (f in data.frames) {
			var pad = f.length % 2;
			totalVideoBytes += 8 + f.length + pad;
		}

		var audioPad = audioBlockSizePerFrame % 2;
		var totalAudioBytes = hasAudio ? numFrames * (8 + audioBlockSizePerFrame + audioPad) : 0;
		var moviDataSize = totalVideoBytes + totalAudioBytes;
		var moviListSize = 4 + moviDataSize;

		output.writeString("RIFF");
		var headerSize = hasAudio ? 316 : 216;
		var totalFileSize = headerSize + moviDataSize;
		output.writeInt32(totalFileSize);
		output.writeString("AVI ");

		output.writeString("LIST");
		output.writeInt32(hasAudio ? 292 : 192);
		output.writeString("hdrl");

		output.writeString("avih");
		output.writeInt32(56);
		output.writeInt32(Std.int(1000000 / fps));
		output.writeInt32(0);
		output.writeInt32(0);
		output.writeInt32(0x10);
		output.writeInt32(numFrames);
		output.writeInt32(0);
		output.writeInt32(hasAudio ? 2 : 1);
		output.writeInt32(0);
		output.writeInt32(tw);
		output.writeInt32(th);
		output.writeInt32(0);
		output.writeInt32(0);
		output.writeInt32(0);
		output.writeInt32(0);

		output.writeString("LIST");
		output.writeInt32(116);
		output.writeString("strl");

		output.writeString("strh");
		output.writeInt32(56);
		output.writeString("vids");
		output.writeString("MJPG");
		output.writeInt32(0);
		output.writeInt16(0);
		output.writeInt16(0);
		output.writeInt32(0);
		output.writeInt32(fpsScale);
		output.writeInt32(fpsRate);
		output.writeInt32(0);
		output.writeInt32(numFrames);
		output.writeInt32(0);
		output.writeInt32(-1);
		output.writeInt32(0);
		output.writeInt16(0);
		output.writeInt16(0);
		output.writeInt16(tw);
		output.writeInt16(th);

		output.writeString("strf");
		output.writeInt32(40);
		output.writeInt32(40);
		output.writeInt32(tw);
		output.writeInt32(th);
		output.writeInt16(1);
		output.writeInt16(24);
		output.writeString("MJPG");
		output.writeInt32(0);
		output.writeInt32(0);
		output.writeInt32(0);
		output.writeInt32(0);
		output.writeInt32(0);

		if (hasAudio) {
			output.writeString("LIST");
			output.writeInt32(92);
			output.writeString("strl");

			output.writeString("strh");
			output.writeInt32(56);
			output.writeString("auds");
			output.writeInt32(0);
			output.writeInt32(0);
			output.writeInt16(0);
			output.writeInt16(0);
			output.writeInt32(0);
			output.writeInt32(1);
			output.writeInt32(sampleRate);
			output.writeInt32(0);
			output.writeInt32(numFrames * samplesPerFrame);
			output.writeInt32(audioBlockSizePerFrame);
			output.writeInt32(-1);
			output.writeInt32(bytesPerSample * channels);
			output.writeInt16(0);
			output.writeInt16(0);
			output.writeInt16(0);
			output.writeInt16(0);

			output.writeString("strf");
			output.writeInt32(16);
			output.writeInt16(1);
			output.writeInt16(channels);
			output.writeInt32(sampleRate);
			output.writeInt32(sampleRate * channels * bytesPerSample);
			output.writeInt16(channels * bytesPerSample);
			output.writeInt16(bitsPerSample);
		}

		output.writeString("LIST");
		output.writeInt32(moviListSize);
		output.writeString("movi");

		var totalCaptured = hasAudio ? data.audioSamples.length : 0;
		var totalNeeded = hasAudio ? numFrames * samplesPerFrame * channels : 0;
		var step = (hasAudio && totalNeeded > 0 && totalCaptured > 0) ? totalCaptured / totalNeeded : 1.0;

		for (i in 0...numFrames) {
			var jpgBytes = data.frames[i];
			output.writeString("00dc");
			output.writeInt32(jpgBytes.length);
			output.writeBytes(jpgBytes, 0, jpgBytes.length);

			if (jpgBytes.length % 2 != 0) {
				output.writeByte(0);
			}

			if (hasAudio) {
				output.writeString("01wb");
				output.writeInt32(audioBlockSizePerFrame);

				var samplesForThisFrame = samplesPerFrame * channels;
				for (s in 0...samplesForThisFrame) {
					var targetIdx = Std.int((i * samplesForThisFrame + s) * step);
					if (targetIdx % 2 != 0) targetIdx--;

					var sampleVal = 0;
					if (targetIdx >= 0 && targetIdx < data.audioSamples.length) {
						var fVal = data.audioSamples[targetIdx];
						if (fVal > 1.0) fVal = 1.0;
						if (fVal < -1.0) fVal = -1.0;
						sampleVal = Std.int(fVal * 32767.0);
					}
					output.writeInt16(sampleVal);
				}

				if (audioBlockSizePerFrame % 2 != 0) {
					output.writeByte(0);
				}
			}
		}
	}
}