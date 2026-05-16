extends Node

func play(audio: AudioStream, single=false, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if not audio:
		return

	if single:
		stop()

	for player in get_children():
		player = player as AudioStreamPlayer

		if not player.playing:
			player.stream = audio
			player.pitch_scale = pitch
			player.volume_db = volume_db
			player.play()
			break

func stop() -> void:
	for player in get_children():
		player = player as AudioStreamPlayer
		player.stop()
