package armory.trait.internal;

import haxe.io.Bytes;
import haxe.io.BytesOutput;
import iron.format.wav.Writer;
import iron.format.wav.Data;
import kha.Sound;
import kha.arrays.Float32Array;
import iron.system.Audio;

class SoundGenerator {

	var samplingRate: Int;
	var channels: Int;
	var bitsPerSample: Int;
	var byteData: BytesOutput;
	var sound: Sound;

	public var channel: kha.audio1.AudioChannel = null;

	public static inline var SOLF_174: Float = 174.0;
	public static inline var SOLF_285: Float = 285.0;
	public static inline var SOLF_396: Float = 396.0;
	public static inline var SOLF_417: Float = 417.0;
	public static inline var SOLF_528: Float = 528.0;
	public static inline var SOLF_639: Float = 639.0;
	public static inline var SOLF_741: Float = 741.0;
	public static inline var SOLF_852: Float = 852.0;
	public static inline var SOLF_963: Float = 963.0;

	public static inline var DO3: Float = 130.81;
	public static inline var DO_S3: Float = 138.59;
	public static inline var RE3: Float = 146.83;
	public static inline var RE_S3: Float = 155.56;
	public static inline var MI3: Float = 164.81;
	public static inline var FA3: Float = 174.61;
	public static inline var FA_S3: Float = 185.00;
	public static inline var SOL3: Float = 196.00;
	public static inline var SOL_S3: Float = 207.65;
	public static inline var LA3: Float = 220.00;
	public static inline var LA_S3: Float = 233.08;
	public static inline var SI3: Float = 246.94;

	public static inline var DO4: Float = 261.63;
	public static inline var DO_S4: Float = 277.18;
	public static inline var RE4: Float = 293.66;
	public static inline var RE_S4: Float = 311.13;
	public static inline var MI4: Float = 329.63;
	public static inline var FA4: Float = 349.23;
	public static inline var FA_S4: Float = 369.99;
	public static inline var SOL4: Float = 392.00;
	public static inline var SOL_S4: Float = 415.30;
	public static inline var LA4: Float = 440.00;
	public static inline var LA_S4: Float = 466.16;
	public static inline var SI4: Float = 493.88;

	public static inline var DO5: Float = 523.25;
	public static inline var DO_S5: Float = 554.37;
	public static inline var RE5: Float = 587.33;
	public static inline var RE_S5: Float = 622.25;
	public static inline var MI5: Float = 659.25;
	public static inline var FA5: Float = 698.46;
	public static inline var FA_S5: Float = 739.99;
	public static inline var SOL5: Float = 783.99;
	public static inline var SOL_S5: Float = 830.61;
	public static inline var LA5: Float = 880.00;
	public static inline var LA_S5: Float = 932.33;
	public static inline var SI5: Float = 987.77;

	public static function noteToFreq(midiNote: Int, baseA4: Float = 440.0): Float {
		return baseA4 * Math.pow(2.0, (midiNote - 69) / 12.0);
	}

	public static function semitonesToFreq(semitones: Int, baseA4: Float = 440.0): Float {
		return baseA4 * Math.pow(2.0, semitones / 12.0);
	}

	public function new(samplingRate: Int = 44100, channels: Int = 1, bitsPerSample: Int = 16) {
		this.samplingRate = samplingRate;
		this.channels = channels;
		this.bitsPerSample = bitsPerSample;
		byteData = new BytesOutput();
	}

	public function generate(): Void {
		if (byteData == null) return;

		var rawBytes = byteData.getBytes();
		var totalSamples = Std.int(rawBytes.length / (bitsPerSample / 8));
		sound = new Sound();
		sound.uncompressedData = new Float32Array(totalSamples);
		sound.sampleRate = samplingRate;
		sound.channels = channels;

		for (i in 0...totalSamples) {
			if (bitsPerSample == 16) {
				var pos = i * 2;
				var val = rawBytes.get(pos) | (rawBytes.get(pos + 1) << 8);
				if ((val & 0x8000) != 0) val -= 0x10000;
				sound.uncompressedData[i] = val / 32767.0;
			} else if (bitsPerSample == 8) {
				var val = rawBytes.get(i) - 128;
				sound.uncompressedData[i] = val / 127.0;
			}
		}
	}

	public function play(loop: Bool = false, stream = false, volume: Float = 1.0): Void {
		if (sound != null){
			channel = Audio.play(sound, loop, stream);
			channel.volume = volume;
		}
	}

	public function stop(): Void {
		if (channel != null) channel.stop();
	}

	public function pause(): Void {
		if (channel != null) channel.pause();
	}

	public function setVolume(volume: Float): Void {
		if (channel != null) channel.volume = volume;
	}

	public function setPitch(pitch: Float): Void {
		if (sound != null) sound.sampleRate = Std.int(samplingRate * pitch);
	}

	public function write(file: String): Void {
		if (byteData == null) return;

		var rawBytes = byteData.getBytes();
		var output = new BytesOutput();
		var writer = new Writer(output);

		var wavData: WAVE = {
			header: {
				format: WAVEFormat.WF_PCM,
				channels: channels,
				samplingRate: samplingRate,
				bitsPerSample: bitsPerSample,
				byteRate: Std.int(samplingRate * channels * bitsPerSample / 8),
				blockAlign: Std.int(channels * bitsPerSample / 8)
			},
			data: rawBytes,
			cuePoints: []
		};

		writer.write(wavData);

		#if kha_krom
		Krom.fileSaveBytes(Krom.getFilesLocation() + "/" + file, output.getBytes().getData());
		
		#elseif kha_html5
		var blob = new js.html.Blob([output.getBytes().getData()], {type: "application"});
		var url = js.html.URL.createObjectURL(blob);
		var a = cast(js.Browser.document.createElement("a"), js.html.AnchorElement);
		a.href = url;
		a.download = file;
		a.click();
		js.html.URL.revokeObjectURL(url);
		#end
	}

	private function writeSample(value: Float): Void {
		if (bitsPerSample == 16) {
			var sampleVal = Std.int(value);
			byteData.writeInt16(sampleVal);
			if (channels > 1) byteData.writeInt16(sampleVal);
		} else if (bitsPerSample == 8) {
			var sampleVal = Std.int(value) + 128;
			byteData.writeByte(sampleVal);
			if (channels > 1) byteData.writeByte(sampleVal);
		}
	}

	public function addTone(frequency: Float, duration: Float): Void {
		if (byteData == null) return;

		var numSamples = Std.int(samplingRate * duration);
		var amplitude = (bitsPerSample == 8) ? 127.0 : 16384.0;

		for (i in 0...numSamples) {
			var t = i / samplingRate;
			var value = Math.sin(2 * Math.PI * frequency * t) * amplitude;
			writeSample(value);
		}
	}

	public function addSilence(duration: Float): Void {
		if (byteData == null) return;

		var numSamples = Std.int(samplingRate * duration);

		for (i in 0...numSamples) {
			writeSample(0.0);
		}
	}

	public function addBridge(startFreq: Float, endFreq: Float, duration: Float): Void {
		if (byteData == null) return;

		var numSamples = Std.int(samplingRate * duration);
		var amplitude = (bitsPerSample == 8) ? 127.0 : 16384.0;

		for (i in 0...numSamples) {
			var progress = i / numSamples;
			var currentFreq = startFreq + (endFreq - startFreq) * progress;
			var t = i / samplingRate;
			var value = Math.sin(2 * Math.PI * currentFreq * t) * amplitude;
			writeSample(value);
		}
	}

	public function addWave(waveType: String, frequency: Float, duration: Float): Void {
		if (byteData == null) return;

		var numSamples = Std.int(samplingRate * duration);
		var amplitude = (bitsPerSample == 8) ? 127.0 : 16384.0;

		for (i in 0...numSamples) {
			var t = i / samplingRate;
			var phase = (t * frequency) - Math.floor(t * frequency);
			var sampleVal: Float = 0.0;

			switch (waveType) {
				case "square":
					sampleVal = (phase < 0.5) ? amplitude : -amplitude;
				case "sawtooth":
					sampleVal = (2.0 * phase - 1.0) * amplitude;
				case "triangle":
					sampleVal = (Math.abs(4.0 * phase - 2.0) - 1.0) * amplitude;
				default:
					sampleVal = Math.sin(2 * Math.PI * frequency * t) * amplitude;
			}

			writeSample(sampleVal);
		}
	}

	public function addChord(frequencies: Array<Float>, duration: Float): Void {
		if (byteData == null) return;

		var numSamples = Std.int(samplingRate * duration);
		var amplitude = (bitsPerSample == 8) ? 127.0 : 16384.0;
		var numFreqs = frequencies.length;
		if (numFreqs == 0) return;

		for (i in 0...numSamples) {
			var t = i / samplingRate;
			var sampleVal: Float = 0.0;
			for (f in frequencies) {
				sampleVal += Math.sin(2 * Math.PI * f * t);
			}
			sampleVal = (sampleVal / numFreqs) * amplitude;
			writeSample(sampleVal);
		}
	}

	public function addNoise(duration: Float): Void {
		if (byteData == null) return;

		var numSamples = Std.int(samplingRate * duration);
		var amplitude = (bitsPerSample == 8) ? 127.0 : 16384.0;

		for (i in 0...numSamples) {
			var sampleVal = (Math.random() * 2.0 - 1.0) * amplitude;
			writeSample(sampleVal);
		}
	}

	public function addEnvelope(frequency: Float, duration: Float, attack: Float, decay: Float, sustain: Float, release: Float): Void {
		if (byteData == null) return;

		var numSamples = Std.int(samplingRate * duration);
		var amplitude = (bitsPerSample == 8) ? 127.0 : 16384.0;

		var attackSamples = Std.int(attack * samplingRate);
		var decaySamples = Std.int(decay * samplingRate);
		var releaseSamples = Std.int(release * samplingRate);
		var sustainSamples = numSamples - attackSamples - decaySamples - releaseSamples;
		if (sustainSamples < 0) sustainSamples = 0;

		for (i in 0...numSamples) {
			var t = i / samplingRate;
			var env: Float = 0.0;

			if (i < attackSamples) {
				env = i / attackSamples;
			} else if (i < attackSamples + decaySamples) {
				var progress = (i - attackSamples) / decaySamples;
				env = 1.0 - progress * (1.0 - sustain);
			} else if (i < attackSamples + decaySamples + sustainSamples) {
				env = sustain;
			} else {
				var progress = (i - attackSamples - decaySamples - sustainSamples) / releaseSamples;
				env = sustain * (1.0 - progress);
				if (env < 0.0) env = 0.0;
			}

			var sampleVal = Math.sin(2 * Math.PI * frequency * t) * amplitude * env;
			writeSample(sampleVal);
		}
	}

	public function addVibrato(frequency: Float, duration: Float, lfoRate: Float, lfoDepth: Float): Void {
		if (byteData == null) return;

		var numSamples = Std.int(samplingRate * duration);
		var amplitude = (bitsPerSample == 8) ? 127.0 : 16384.0;
		var currentPhase: Float = 0.0;

		for (i in 0...numSamples) {
			var t = i / samplingRate;
			var freqOffset = Math.sin(2 * Math.PI * lfoRate * t) * lfoDepth;
			var currentFreq = frequency + freqOffset;

			currentPhase += (2 * Math.PI * currentFreq) / samplingRate;
			var sampleVal = Math.sin(currentPhase) * amplitude;
			writeSample(sampleVal);
		}
	}

	public function addSweep(startFreq: Float, endFreq: Float, duration: Float): Void {
		if (byteData == null) return;

		var numSamples = Std.int(samplingRate * duration);
		var amplitude = (bitsPerSample == 8) ? 127.0 : 16384.0;
		var currentPhase: Float = 0.0;

		for (i in 0...numSamples) {
			var progress = i / numSamples;
			var currentFreq = startFreq * Math.pow(endFreq / startFreq, progress);

			currentPhase += (2 * Math.PI * currentFreq) / samplingRate;
			var sampleVal = Math.sin(currentPhase) * amplitude;
			writeSample(sampleVal);
		}
	}
}