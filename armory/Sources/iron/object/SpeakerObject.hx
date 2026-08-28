package iron.object;

import kha.FastFloat;
import kha.Sound;
import kha.audio1.AudioChannel;
import iron.data.Data;
import iron.data.SceneFormat;
import iron.math.Vec4;
import iron.system.Audio;

class SpeakerObject extends Object {

#if arm_audio

	public var data: TSpeakerData;
	public var paused(default, null) = false;
	public var sound(default, null): Sound = null;
	public var channels(default, null): Array<AudioChannel> = [];
	public var volume(default, null) : FastFloat;
	public var sampleRate(default, null) : Int;

	public function new(data: TSpeakerData) {
		super();

		this.data = data;

		Scene.active.speakers.push(this);

		if (data.sound == "") return;

		Data.getSound(data.sound, function(sound: Sound) {
			this.sound = cloneSound(sound);
			App.notifyOnInit(init);
		});
	}

	function init() {
		sampleRate = sound.sampleRate;
		if (data.pitch != 1.0)
			sound.sampleRate = Std.int(sampleRate * data.pitch);
		if (visible && data.play_on_start) play();
	}

	public function play(): AudioChannel {
		if (sound == null || data.muted) return null;
		if (paused) {
			for (c in channels) c.play();
			paused = false;
			return null;
		}
		var channel = Audio.play(sound, data.loop, data.stream);
		if (channel != null) {
			channels.push(channel);
			if (data.attenuation > 0 && channels.length == 1) App.notifyOnUpdate(update);
		}
		return channel;
	}

	public function pause() {
		for (c in channels) c.pause();
		paused = true;
	}

	public function stop() {
		for (c in channels) c.stop();
		channels.splice(0, channels.length);
	}

	public function setSound(sound: String) {
		if (sound == null) return;

		data.sound = sound;

		Data.getSound(sound, function(sound: Sound) {
			this.sound = cloneSound(sound);
		});

		sampleRate = this.sound.sampleRate;
		if (data.pitch != 1.0)
			this.sound.sampleRate = Std.int(sampleRate * data.pitch);
	}

	public function setVolume(volume: FastFloat) {
		data.volume = volume;
	}

	public function setPosition(position: Float) {
		for (c in channels)
			if (position < c.length) c.position = position;
	}

	function update() {
		if (paused) return;
		for (c in channels) if (c.finished) channels.remove(c);
		if (channels.length == 0) {
			App.removeUpdate(update);
			return;
		}

		if (data.attenuation > 0) {
			var distance = Vec4.distance(Scene.active.camera.transform.world.getLoc(), transform.world.getLoc());
			distance = Math.max(Math.min(data.distance_max, distance), data.distance_reference);
			volume = data.distance_reference / (data.distance_reference + data.attenuation * (distance - data.distance_reference));
			volume *= data.volume;
		}
		else {
			volume = data.volume;
		}

		if (volume > data.volume_max) volume = data.volume_max;
		else if (volume < data.volume_min) volume = data.volume_min;

		for (c in channels) c.volume = volume;
	}

	public override function remove() {
		stop();
		if (Scene.active != null) Scene.active.speakers.remove(this);
		super.remove();
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

#end

}
