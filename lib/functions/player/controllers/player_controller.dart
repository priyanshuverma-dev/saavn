import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:savaan/functions/explore/controllers/explore_controller.dart';
import 'package:savaan/functions/player/views/common.dart';
import 'package:savaan/models/helpers/download_quality.dart';
import 'package:savaan/models/song_metadata.dart';
import 'package:savaan/models/song_model.dart';

final playerControllerProvider =
    StateNotifierProvider<PlayerController, bool>((ref) {
  return PlayerController(
      exploreController: ref.watch(exploreControllerProvider.notifier));
});

final getAudioPlayer = Provider.autoDispose(
    (ref) => ref.watch(playerControllerProvider.notifier).getPlayer);

class PlayerController extends StateNotifier<bool> {
  final ExploreController _exploreController;
  final _player = AudioPlayer();
  PlayerController({required ExploreController exploreController})
      : _exploreController = exploreController,
        super(false);

  // @override
  // void initState() {
  //   ();
  //   // super.initState();
  // }

  AudioPlayer get getPlayer => _player;
  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
          _player.positionStream,
          _player.bufferedPositionStream,
          _player.durationStream,
          (position, bufferedPosition, duration) => PositionData(
              position, bufferedPosition, duration ?? Duration.zero));

  void initializePlayer() async {
    // final session = await AudioSession.instance;

    // await session.configure(const AudioSessionConfiguration.music());
    // Listen to errors during playback.
    _player.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
      print('A stream error occurred: $e');
    });
    try {
      // _playlist = await ref.read(getPlaylistProvider(SongModel.empty()));
      // print(_player);
      // await _player.setAudioSource(_playlist,
      //     preload: kIsWeb || defaultTargetPlatform != TargetPlatform.linux);
    } on PlayerException catch (e) {
      print("Error loading audio source: $e");
    }

    _player.positionDiscontinuityStream.listen((discontinuity) {
      if (discontinuity.reason == PositionDiscontinuityReason.autoAdvance) {
        // _showItemFinished(discontinuity.previousEvent.currentIndex);
      }
    });

    _player.processingStateStream.listen((state) {
      print("PLAYER PROCESSING STATE: $state");
      if (state == ProcessingState.completed) {
        // _showItemFinished(_player.currentIndex);
      }
    });
  }

  void seetToNext() async {
    await _player.seekToNext();
  }

  void setSong({required SongModel song}) async {
    // Listen to errors during playback.
    _player.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
      print('A stream error occurred: $e');
    });
    try {
      final songsObjects =
          await _exploreController.getSongRecommendationData(song.id);

      print(songsObjects);
      final playlist = ConcatenatingAudioSource(
        useLazyPreparation: true,
        shuffleOrder: DefaultShuffleOrder(),
        children: [],
      );
      songsObjects.insert(0, song);

      for (var i = 0; i < songsObjects.length; i++) {
        final uri = songsObjects[i]
            .downloadUrl
            .where((element) => element.quality == SongQualityType.high)
            .toList()[0]
            .url;

        playlist.add(AudioSource.uri(Uri.parse(uri),
            tag: SongMetadata(
              title: songsObjects[i].name,
              album: songsObjects[i].album.name,
              albumArtist: "Savaan",
              artist: "Savan",
              thumbnail: songsObjects[i].image[2].url,
              copyright: songsObjects[i].copyright,
              downloadUrl: songsObjects[i].downloadUrl,
              duration: songsObjects[i].duration,
              explicitContent: songsObjects[i].explicitContent,
              hasLyrics: songsObjects[i].hasLyrics,
              id: songsObjects[i].id,
              image: songsObjects[i].image,
              label: songsObjects[i].label,
              language: songsObjects[i].language,
              lyricsId: songsObjects[i].lyricsId,
              name: songsObjects[i].name,
              playCount: songsObjects[i].playCount,
              releaseDate: songsObjects[i].releaseDate,
              type: songsObjects[i].type,
              url: songsObjects[i].url,
              year: songsObjects[i].year,
            )));
      }

      await _player.setAudioSource(playlist,
          preload: kIsWeb || defaultTargetPlatform != TargetPlatform.linux);

      print(_player.sequence!.length);
    } on PlayerException catch (e) {
      print("Error loading audio source: $e");
    }

    _player.positionDiscontinuityStream.listen((discontinuity) {
      if (discontinuity.reason == PositionDiscontinuityReason.autoAdvance) {
        // _showItemFinished(discontinuity.previousEvent.currentIndex);
      }
    });

    _player.processingStateStream.listen((state) {
      print("PLAYER PROCESSING STATE: $state");
      if (state == ProcessingState.completed) {
        // _showItemFinished(_player.currentIndex);
      }
    });
  }
}
