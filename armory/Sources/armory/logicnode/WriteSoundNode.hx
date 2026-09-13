package armory.logicnode;

import iron.format.wav.Writer;
import iron.format.wav.Data;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import kha.audio2.Audio;
import kha.audio2.Buffer;
import kha.internal.IntBox;

class WriteSoundNode extends LogicNode {
	var recording: Bool = false;
	var bytesOutput: BytesOutput;
	var oldCallback: IntBox -> Buffer -> Void;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		if (from == 0) {
			if (!recording) {
				recording = true;
				bytesOutput = new BytesOutput();
				bytesOutput.bigEndian = false;
				oldCallback = Audio.audioCallback;
				Audio.audioCallback = audioCallback;
			}
			runOutput(0);
		}
		else if (from == 1) {
			if (recording) {
				recording = false;
				Audio.audioCallback = oldCallback;
				saveSound();
				runOutput(1);
			}
		}
	}

	function audioCallback(samples: IntBox, buffer: Buffer): Void {
		var start: Int = buffer.writeLocation;
		if (oldCallback != null) {
			oldCallback(samples, buffer);
		}
		var volume: Float = inputs[3].get();
		if (volume == null || volume <= 0.0) return;

		var count: Int = samples.value;
		for (i in 0...count) {
			var idx: Int = (start + i) % buffer.size;
			var fVal: Float = buffer.data.get(idx) * volume;
			if (fVal < -1.0) fVal = -1.0;
			if (fVal > 1.0) fVal = 1.0;
			var iVal: Int = Std.int(fVal * 32767.0);
			bytesOutput.writeInt16(iVal);
		}
	}

	function saveSound(): Void {
		if (bytesOutput == null || bytesOutput.length == 0) return;
		var file: String = inputs[2].get();

		var pcmData: Bytes = bytesOutput.getBytes();
		var wavData: WAVE = {
			header: {
				format: WF_PCM,
				channels: 2,
				samplingRate: Audio.samplesPerSecond,
				byteRate: Std.int(Audio.samplesPerSecond * 2 * 2),
				blockAlign: 4,
				bitsPerSample: 16
			},
			data: pcmData,
			cuePoints: null
		};

		var bo: BytesOutput = new BytesOutput();
		bo.bigEndian = false;
		var writer: Writer = new Writer(bo);
		writer.write(wavData);

		#if kha_krom
		Krom.fileSaveBytes(Krom.getFilesLocation() + "/" + file, bo.getBytes().getData());

		#elseif kha_html5
		var blob = new js.html.Blob([bo.getBytes().getData()], {type: "application"});
		var url = js.html.URL.createObjectURL(blob);
		var a = cast(js.Browser.document.createElement("a"), js.html.AnchorElement);
		a.href = url;
		a.download = file;
		a.click();
		js.html.URL.revokeObjectURL(url);
		#end
	}
}