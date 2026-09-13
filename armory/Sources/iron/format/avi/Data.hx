package iron.format.avi;

import haxe.io.Bytes;

typedef AviData = {
	var width: Int;
	var height: Int;
	var fps: Float;
	var frames: Array<Bytes>;
	var audioSamples: Array<Float>;
	var sampleRate: Int;
	var channels: Int;
}