package armory.trait;

import armory.trait.internal.SoundGenerator;
import iron.math.Vec4;
import kha.graphics2.Graphics;
import kha.Color;

class SoundController extends iron.Trait {

	var wav: SoundGenerator;
	var peaks: Array<Float> = [];
	var x: Int;
	var y: Int;
	var width: Int;
	var height: Int;
	var lineCol: Color;
	var waveCol: Color;
	var waveBgCol: Color;
	var bgCol: Color;

	public function new() {
		super();
		notifyOnInit(function() {
			wav = new SoundGenerator();
			
			wav.addTone(440.00, 1.0);
			wav.addSilence(0.5);
			wav.addBridge(440.00, 880.00, 2.0);
			wav.addTone(880.00, 1.0);
			wav.addWave("square", 440.00, 1.0);
			wav.addChord([261.63, 329.63, 392.00], 1.0);
			wav.addNoise(0.5);
			wav.addEnvelope(440.00, 1.5, 0.1, 0.2, 0.7, 0.3);
			wav.addVibrato(440.00, 1.0, 5.0, 10.0);
			wav.addSweep(200.00, 800.00, 1.0);
			wav.generate();

		});
	}

	public function play(): Void {
		wav.play();
	}

	public function getAmplitude(?position: Null<Float>): Float {
		if (wav == null || wav.channel == null || wav.channel.length <= 0 || peaks.length == 0) return 0.0;
		var pos = position != null ? position : wav.channel.position;
		var progress = Math.min(1.0, Math.max(0.0, pos / wav.channel.length));
		return peaks[Std.int(progress * (peaks.length - 1))];
	}

	public function addDraw(x: Int, y: Int, width: Int, height: Int, lineCol: Vec4, waveCol: Vec4, waveBgCol: Vec4, bgCol: Vec4): Void {
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
		this.lineCol = Color.fromFloats(lineCol.x, lineCol.y, lineCol.z, lineCol.w);
		this.waveCol = Color.fromFloats(waveCol.x, waveCol.y, waveCol.z, waveCol.w);
		this.waveBgCol = Color.fromFloats(waveBgCol.x, waveBgCol.y, waveBgCol.z, waveBgCol.w);
		this.bgCol = Color.fromFloats(bgCol.x, bgCol.y, bgCol.z, bgCol.w);

		var data = wav.sound.uncompressedData;

		if (data != null) {
			var sampleCount = data.length;
			var samplesPerPixel = Std.int(sampleCount / width);

			peaks = [];
			for (i in 0...width) {
				var max = 0.0;
				var start = i * samplesPerPixel;
				var end = start + samplesPerPixel;
				var mid = Std.int(start + (samplesPerPixel / 2));

				for (j in start...end) {
					if (j >= sampleCount) break;
					var val = Math.abs(data.get(j));
					if (val > max) max = val;
				}

				var sample = mid < sampleCount ? Math.abs(data.get(mid)) : 0.0;
				peaks.push((max + sample) / 2);
			}
		}

		notifyOnRender2D(drawWaveform);
	}

	public function removeDraw(): Void {
		removeRender2D(drawWaveform);
	}

	public function drawWaveform(g: Graphics): Void {
		if (wav.channel == null) return;

		var len = wav.channel.length;
		var progress = len > 0 ? Math.min(1.0, Math.max(0.0, wav.channel.position / len)) : 0.0;
		var progressPixel = Std.int(progress * width);
		var halfHeight = height / 2;

		g.color = bgCol;
		g.fillRect(x, y, width, height);

		for (i in 0...peaks.length) {
			g.color = (i < progressPixel) ? waveCol : waveBgCol;
			var pHeight = peaks[i] * halfHeight;
			g.drawLine(x + i, y + halfHeight - pHeight, x + i, y + halfHeight + pHeight, 1.0);
		}

		g.color = lineCol;
		g.fillRect(x + progressPixel - 1, y, 2, height);
	}
}