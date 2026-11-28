package armory.logicnode;

import armory.trait.internal.SoundGenerator;
import armory.renderpath.RenderToTexture;
import kha.Color;

class SoundGenDrawNode extends LogicNode {

	var generator: SoundGenerator;
	var progress: Float = 0.0;

	var cachedGenerator: SoundGenerator = null;
	var cachedWidth: Int = -1;
	var cachedPeaks: Array<Float> = [];

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		RenderToTexture.ensure2DContext("SoundGenDrawNode");

		generator = inputs[1].get();

		if (generator != null && generator.sound != null) {
			var x: Int = inputs[2].get();
			var y: Int = inputs[3].get();
			var width: Int = inputs[4].get();
			var height: Int = inputs[5].get();

			var lineVec = inputs[6].get();
			var waveVec = inputs[7].get();
			var waveBgVec = inputs[8].get();
			var bgVec = inputs[9].get();

			if (width > 0 && height > 0) {
				if (cachedGenerator != generator || cachedWidth != width) {
					cachedGenerator = generator;
					cachedWidth = width;
					cachedPeaks = generator.buildWaveform(width);
				}

				var peaks = cachedPeaks;

				if (generator.channel != null && generator.channel.length > 0)
					progress = Math.min(1.0, Math.max(0.0, generator.channel.position / generator.channel.length));

				var progressPixel = Std.int(progress * width);
				var halfHeight: Float = height / 2;
				var g = RenderToTexture.g;

				g.color = Color.fromFloats(bgVec.x, bgVec.y, bgVec.z, bgVec.w);
				g.fillRect(x, y, width, height);

				for (i in 0...peaks.length) {
					g.color = (i < progressPixel)
						? Color.fromFloats(waveVec.x, waveVec.y, waveVec.z, waveVec.w)
						: Color.fromFloats(waveBgVec.x, waveBgVec.y, waveBgVec.z, waveBgVec.w);

					var pHeight = peaks[i] * halfHeight;
					g.drawLine(x + i, y + halfHeight - pHeight, x + i, y + halfHeight + pHeight, 1.0);
				}

				g.color = Color.fromFloats(lineVec.x, lineVec.y, lineVec.z, lineVec.w);
				g.fillRect(x + progressPixel - 1, y, 2, height);
			}
		}

		runOutput(0);
	}

	override function get(from: Int): Dynamic {
		if (generator == null || generator.sound == null) return 0;

		return switch(from){
			case 1: generator.sound.uncompressedData.length / (generator.sound.sampleRate * generator.sound.channels);
			case 2:	generator.channel != null ? generator.channel.position : 0.0;
			default: cachedPeaks[Std.int(progress * (cachedPeaks.length - 1))];
			}
	}
}