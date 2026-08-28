package armory.logicnode;

import kha.Sound;
import kha.audio1.AudioChannel;
import iron.system.Audio;
import iron.data.Data;

class PlaySoundRawNode extends LogicNode {

	/** The name of the sound */
	public var property0: String;
	/** Whether to loop the playback */
	public var property1: Bool;
	/** Retrigger */
	public var property2: Bool;
	/** Whether to stream the sound from disk **/
	public var property3: Bool;

	public var property4: String;

	var soundName: String = null;
	var sound: Sound = null;
	var channel: AudioChannel = null;
	var sampleRate: Int;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		switch (from) {
			case Play:
				var file: String = property4 == 'Sound' ? property0 : inputs[6].get();
				if (soundName != file) {
					soundName = file;
					Data.getSound(file, function(s: Sound) {
						this.sound = cloneSound(s);
						this.sampleRate = s.sampleRate;
					});
				}

				// Resume
				if (channel != null) {
					if (property2) channel.stop();
					channel.play();
					channel.volume = inputs[4].get();
				}
				// Start
				else if (sound != null) {
					sound.sampleRate = Std.int(sampleRate * inputs[5].get());
					channel = Audio.play(sound, property1, property3);
					channel.volume = inputs[4].get();
				}

				tree.notifyOnUpdate(this.onUpdate);
				runOutput(0);

			case Pause:
				if (channel != null) channel.pause();
				tree.removeUpdate(this.onUpdate);

			case Stop:
				if (channel != null) channel.stop();
				tree.removeUpdate(this.onUpdate);
				runOutput(2);
			
			case SetVolume:
				if (channel != null) channel.volume = inputs[4].get();
		}
	}

	function onUpdate() {
		if (channel != null) {
			// Done
			if (channel.finished) {
				channel = null;
				runOutput(2);
			}
			// Running
			else runOutput(1);
		}
	}

	function cloneSound(sound: Sound): Sound {
		if (sound == null) return null;
		var s = Type.createEmptyInstance(Sound);
		s.compressedData = sound.compressedData;
		s.uncompressedData = sound.uncompressedData;
		s.sampleRate = sound.sampleRate;
		s.length = sound.length;
		s.channels = sound.channels;
		return s;
	}

	override function get(from: Int): Dynamic {
		return
			channel != null ? from == 3 ? channel.length : channel.position : null;
	}
}

private enum abstract PlayState(Int) from Int to Int {
	var Play = 0;
	var Pause = 1;
	var Stop = 2;
	var SetVolume = 3;
}
