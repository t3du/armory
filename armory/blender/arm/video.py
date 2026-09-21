import os
import shutil
import struct
import wave

import bpy


def _clear_sequence_editor(scene):
    if scene.sequence_editor is None:
        scene.sequence_editor_create()
    for sequence in list(scene.sequence_editor.sequences):
        scene.sequence_editor.sequences.remove(sequence)


def _read_jpeg_frames(temp_dir, frame_start, frame_end):
    frames = []
    for frame_number in range(frame_start, frame_end + 1):
        path = os.path.join(temp_dir, f"frame_{frame_number:05d}.jpg")
        if not os.path.exists(path):
            path = os.path.join(temp_dir, f"frame_{frame_number:05d}.jpeg")
        if os.path.exists(path):
            with open(path, "rb") as frame_file:
                frames.append(frame_file.read())
    return frames


def _read_audio(temp_wav_path, frame_count, fps):
    if not os.path.exists(temp_wav_path) or os.path.getsize(temp_wav_path) <= 44:
        return None

    with wave.open(temp_wav_path, "rb") as wav_file:
        channels = wav_file.getnchannels()
        sample_width = wav_file.getsampwidth()
        sample_rate = wav_file.getframerate()
        pcm_data = wav_file.readframes(wav_file.getnframes())
    max_pcm_bytes = int(frame_count * sample_rate / fps) * channels * sample_width
    return channels, sample_width, sample_rate, pcm_data[:max_pcm_bytes]


def _write_avi(output_path, jpeg_frames, audio_data, fps, width, height):
    fps_rate = max(1, int(round(fps)))
    has_audio = audio_data is not None
    if has_audio:
        channels, sample_width, sample_rate, pcm_data = audio_data
    else:
        channels = 2
        sample_width = 2
        sample_rate = 44100
        pcm_data = b""

    block_align = channels * sample_width
    bytes_per_second = sample_rate * block_align
    pcm_offset = 0
    movi_data = bytearray()
    idx1_data = bytearray()
    movi_offset = 4
    max_frame_size = 0
    max_audio_chunk_size = 0

    for frame_index, frame in enumerate(jpeg_frames):
        frame_size = len(frame)
        max_frame_size = max(max_frame_size, frame_size)
        frame_padding = b"\x00" if frame_size % 2 else b""
        chunk_id = b"00dc"
        movi_data.extend(chunk_id + struct.pack("<I", frame_size) + frame + frame_padding)
        idx1_data.extend(chunk_id + struct.pack("<III", 0x10, movi_offset, frame_size))
        movi_offset += 8 + frame_size + len(frame_padding)

        if has_audio and pcm_offset < len(pcm_data):
            next_pcm_offset = int((frame_index + 1) * sample_rate / fps) * block_align
            if frame_index == len(jpeg_frames) - 1:
                next_pcm_offset = len(pcm_data)
            audio_chunk = pcm_data[pcm_offset:next_pcm_offset]
            pcm_offset = next_pcm_offset
            audio_size = len(audio_chunk)
            max_audio_chunk_size = max(max_audio_chunk_size, audio_size)
            if audio_size > 0:
                audio_padding = b"\x00" if audio_size % 2 else b""
                audio_id = b"01wb"
                movi_data.extend(audio_id + struct.pack("<I", audio_size) + audio_chunk + audio_padding)
                idx1_data.extend(audio_id + struct.pack("<III", 0x10, movi_offset, audio_size))
                movi_offset += 8 + audio_size + len(audio_padding)

    num_frames = len(jpeg_frames)
    num_streams = 2 if has_audio else 1
    avih = struct.pack(
        "<IIIIIIIIIIIIII",
        int(1000000 / fps_rate),
        bytes_per_second + max_frame_size * fps_rate,
        0,
        0x10,
        num_frames,
        0,
        num_streams,
        max(max_frame_size, max_audio_chunk_size),
        width,
        height,
        0,
        0,
        0,
        0,
    )
    avih_chunk = b"avih" + struct.pack("<I", len(avih)) + avih

    strh_video = struct.pack(
        "<4s4sIHHIIIIIIIIhhhh",
        b"vids",
        b"MJPG",
        0,
        0,
        0,
        0,
        1,
        fps_rate,
        0,
        num_frames,
        max_frame_size,
        0xFFFFFFFF,
        0,
        0,
        0,
        width,
        height,
    )
    strf_video = struct.pack(
        "<IiiHH4sIiiII",
        40,
        width,
        height,
        1,
        24,
        b"MJPG",
        width * height * 3,
        0,
        0,
        0,
        0,
    )
    video_list_data = b"strh" + struct.pack("<I", len(strh_video)) + strh_video
    video_list_data += b"strf" + struct.pack("<I", len(strf_video)) + strf_video
    header_data = b"LIST" + struct.pack("<I", len(video_list_data) + 4) + b"strl" + video_list_data

    if has_audio:
        total_audio_blocks = len(pcm_data) // block_align
        strh_audio = struct.pack(
            "<4s4sIHHIIIIIIIIhhhh",
            b"auds",
            b"\x01\x00\x00\x00",
            0,
            0,
            0,
            0,
            1,
            sample_rate,
            0,
            total_audio_blocks,
            max_audio_chunk_size,
            0xFFFFFFFF,
            block_align,
            0,
            0,
            0,
            0,
        )
        strf_audio = struct.pack(
            "<HHIIHH",
            1,
            channels,
            sample_rate,
            bytes_per_second,
            block_align,
            sample_width * 8,
        )
        audio_list_data = b"strh" + struct.pack("<I", len(strh_audio)) + strh_audio
        audio_list_data += b"strf" + struct.pack("<I", len(strf_audio)) + strf_audio
        header_data += b"LIST" + struct.pack("<I", len(audio_list_data) + 4) + b"strl" + audio_list_data

    header_list = b"LIST" + struct.pack("<I", len(header_data) + len(avih_chunk) + 4) + b"hdrl" + avih_chunk + header_data
    movie_list = b"LIST" + struct.pack("<I", len(movi_data) + 4) + b"movi" + movi_data
    index_chunk = b"idx1" + struct.pack("<I", len(idx1_data)) + idx1_data
    riff_content = b"AVI " + header_list + movie_list + index_chunk

    with open(output_path, "wb") as output_file:
        output_file.write(b"RIFF" + struct.pack("<I", len(riff_content)) + riff_content)


def _convert_video(scene, item, project_dir):
    video_name = os.path.basename(item.video_name)
    if not video_name:
        raise ValueError("Video name is empty")

    convert_dir = os.path.join(project_dir, "Convert")
    bundled_dir = os.path.join(project_dir, "Bundled")
    temp_dir = os.path.join(project_dir, "TEMP", os.path.splitext(video_name)[0])
    input_path = os.path.join(convert_dir, video_name)
    output_path = os.path.join(bundled_dir, os.path.splitext(video_name)[0] + ".avi")

    if not os.path.isfile(input_path):
        raise FileNotFoundError(f"Video not found in Convert: {video_name}")

    os.makedirs(bundled_dir, exist_ok=True)
    os.makedirs(os.path.dirname(temp_dir), exist_ok=True)
    if os.path.exists(temp_dir):
        shutil.rmtree(temp_dir)
    os.makedirs(temp_dir)

    _clear_sequence_editor(scene)
    movie_strip = scene.sequence_editor.sequences.new_movie(
        name="InputVideo",
        filepath=input_path,
        channel=1,
        frame_start=1,
    )

    first_frame = max(1, int(item.frame_start))
    last_frame = movie_strip.frame_final_duration if item.frame_end < 0 else min(int(item.frame_end), movie_strip.frame_final_duration)
    if last_frame < first_frame:
        raise ValueError(f"Frame End is before Frame Start for {video_name}")

    sound_strip = None
    if item.audio:
        try:
            sound_strip = scene.sequence_editor.sequences.new_sound(
                name="InputAudio",
                filepath=input_path,
                channel=2,
                frame_start=1,
            )
            sound_strip.frame_final_start = first_frame
            sound_strip.frame_final_duration = last_frame - first_frame + 1
        except Exception as error:
            print(f"Audio strip could not be loaded for {video_name}: {error}")

    source_width = int(movie_strip.elements[0].orig_width) if movie_strip.elements else item.width
    source_height = int(movie_strip.elements[0].orig_height) if movie_strip.elements else item.height
    width = int(item.width) if item.width > 0 else source_width
    height = int(item.height) if item.height > 0 else source_height
    movie_strip.transform.scale_x = width / source_width if source_width else 1.0
    movie_strip.transform.scale_y = height / source_height if source_height else 1.0

    orig_res_x = scene.render.resolution_x
    orig_res_y = scene.render.resolution_y
    orig_pct = scene.render.resolution_percentage
    orig_step = scene.frame_step
    orig_start = scene.frame_start
    orig_end = scene.frame_end

    orig_fps_val = float(movie_strip.fps) if movie_strip.fps else 30.0
    fps = float(item.fps) if item.fps > 0 else orig_fps_val

    step = max(1, int(round(orig_fps_val / fps)))
    fps = orig_fps_val / step

    try:
        scene.frame_start = first_frame
        scene.frame_end = last_frame
        scene.frame_step = step

        scene.render.resolution_x = width
        scene.render.resolution_y = height
        scene.render.resolution_percentage = 100
        scene.render.pixel_aspect_x = 1.0
        scene.render.pixel_aspect_y = 1.0
        scene.render.filepath = os.path.join(temp_dir, "frame_#####")
        scene.render.image_settings.file_format = "JPEG"
        scene.render.image_settings.quality = int(item.quality)

        bpy.ops.render.render(animation=True)

    finally:
        scene.render.resolution_x = orig_res_x
        scene.render.resolution_y = orig_res_y
        scene.render.resolution_percentage = orig_pct
        scene.frame_step = orig_step
        scene.frame_start = orig_start
        scene.frame_end = orig_end

    jpeg_frames = _read_jpeg_frames(temp_dir, first_frame, last_frame)
    if not jpeg_frames:
        raise RuntimeError(f"No rendered frames were produced for {video_name}")

    audio_data = None
    if item.audio and sound_strip is not None:
        temp_wav_path = os.path.join(temp_dir, "audio.wav")
        temp_scene = None
        try:
            temp_scene = bpy.data.scenes.new(name="TempAudioScene")
            temp_scene.sequence_editor_create()

            temp_strip = temp_scene.sequence_editor.sequences.new_sound(
                name="TempAudio",
                filepath=input_path,
                channel=1,
                frame_start=1,
            )
            temp_strip.frame_final_start = first_frame
            temp_strip.frame_final_duration = last_frame - first_frame + 1

            temp_scene.frame_start = first_frame
            temp_scene.frame_end = last_frame
            temp_scene.render.fps = max(1, int(round(orig_fps_val)))
            temp_scene.render.fps_base = temp_scene.render.fps / orig_fps_val

            with bpy.context.temp_override(scene=temp_scene):
                bpy.ops.sound.mixdown(filepath=temp_wav_path, container="WAV", codec="PCM")

            audio_data = _read_audio(temp_wav_path, len(jpeg_frames), fps)
        except Exception as error:
            print(f"Audio extraction failed for {video_name}: {error}")
        finally:
            if temp_scene is not None:
                bpy.data.scenes.remove(temp_scene)

    _write_avi(output_path, jpeg_frames, audio_data, fps, width, height)
    shutil.rmtree(temp_dir, ignore_errors=True)
    return output_path

def convert_videos(video_items, project_dir):
    scene = bpy.context.scene
    converted_paths = []
    errors = []
    try:
        for item in video_items:
            try:
                output_path = _convert_video(scene, item, project_dir)
                converted_paths.append(output_path)
                print(f"Video conversion completed: {output_path}")
            except Exception as error:
                errors.append(str(error))
                print(f"Video conversion failed: {error}")
    finally:
        _clear_sequence_editor(scene)
        shutil.rmtree(os.path.join(project_dir, "TEMP"), ignore_errors=True)
    return converted_paths, errors