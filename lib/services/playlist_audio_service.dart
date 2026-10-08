import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/playlist.dart';
import '../models/music_project.dart';
import '../repository/project_repository.dart';

/// Background audio service for playlist playback
class PlaylistAudioService extends BaseAudioHandler with QueueHandler, SeekHandler {
  final ProjectRepository _repository;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<_PlaylistItem> _playlistItems = [];
  int _currentIndex = 0;
  bool _isPlaying = false;

  // Stream controllers for communication with UI
  final _currentIndexController = StreamController<int>.broadcast();
  final _isPlayingController = StreamController<bool>.broadcast();
  final _playlistController = StreamController<List<_PlaylistItem>>.broadcast();

  // Getters for UI communication
  Stream<int> get currentIndexStream => _currentIndexController.stream;
  Stream<bool> get isPlayingStream => _isPlayingController.stream;
  Stream<List<_PlaylistItem>> get playlistStream => _playlistController.stream;

  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  List<_PlaylistItem> get playlistItems => List.unmodifiable(_playlistItems);

  PlaylistAudioService(this._repository) {
    _init();
  }

  Future<void> _init() async {
    // Configure audio session for background playback
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
      androidWillPauseWhenDucked: true,
    ));

    // Set up audio player listeners
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isPlayingController.add(_isPlaying);

      // Update media item controls
      playbackState.add(playbackState.value.copyWith(
        playing: _isPlaying,
        controls: [
          MediaControl.skipToPrevious,
          _isPlaying ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
      ));
    });

    _audioPlayer.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
      ));
    });

    _audioPlayer.durationStream.listen((duration) {
      if (duration != null && _playlistItems.isNotEmpty) {
        final currentItem = _playlistItems[_currentIndex];
        mediaItem.add(MediaItem(
          id: currentItem.projectId,
          album: 'Playlist',
          title: currentItem.displayName,
          artist: currentItem.fileName ?? 'Unknown',
          duration: duration,
          artUri: Uri.parse('android.resource://com.bandpassrecords.dpm/drawable/ic_launcher'),
        ));
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _playNext();
      }
    });

    // Set initial playback state
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      processingState: AudioProcessingState.idle,
    ));
  }

  Future<void> loadPlaylist(Playlist playlist) async {
    _playlistItems.clear();
    _currentIndex = 0;

    // Load playlist items
    for (final projectId in playlist.projectIds) {
      try {
        final projects = _repository.getAllProjects();
        final project = projects.firstWhere((p) => p.id == projectId);
        if (project.previewSongPath != null &&
            project.previewSongPath!.isNotEmpty &&
            !project.previewSongPath!.startsWith('drive://')) {
          _playlistItems.add(_PlaylistItem(project));
        }
      } catch (_) {
        // Skip invalid projects
      }
    }

    _playlistController.add(List.unmodifiable(_playlistItems));
    queue.value = _playlistItems.map((item) => MediaItem(
      id: item.projectId,
      album: 'Playlist',
      title: item.displayName,
      artist: item.fileName ?? 'Unknown',
    )).toList();
  }

  Future<void> play() async {
    if (_playlistItems.isEmpty) return;

    if (_audioPlayer.playerState.processingState == ProcessingState.idle) {
      await _playCurrentSong();
    } else {
      await _audioPlayer.play();
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _isPlaying = false;
    _isPlayingController.add(false);
  }

  Future<void> skipToNext() async {
    await _playNext();
  }

  Future<void> skipToPrevious() async {
    if (_currentIndex > 0) {
      _currentIndex--;
      _currentIndexController.add(_currentIndex);
      await _playCurrentSong();
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> playItemAtIndex(int index) async {
    if (index >= 0 && index < _playlistItems.length) {
      _currentIndex = index;
      _currentIndexController.add(_currentIndex);
      await _playCurrentSong();
    }
  }

  Future<void> _playCurrentSong() async {
    if (_currentIndex >= _playlistItems.length) {
      await stop();
      return;
    }

    final item = _playlistItems[_currentIndex];
    final filePath = item.previewSongPath;

    if (filePath == null || filePath.isEmpty) {
      await _playNext();
      return;
    }

    final file = File(filePath);
    if (!await file.exists()) {
      await _playNext();
      return;
    }

    try {
      await _audioPlayer.setFilePath(filePath);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing audio: $e');
      await _playNext();
    }
  }

  Future<void> _playNext() async {
    if (_currentIndex < _playlistItems.length - 1) {
      _currentIndex++;
      _currentIndexController.add(_currentIndex);
      await _playCurrentSong();
    } else {
      await stop();
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
    await super.onTaskRemoved();
  }

  void dispose() {
    _audioPlayer.dispose();
    _currentIndexController.close();
    _isPlayingController.close();
    _playlistController.close();
  }
}

/// Simplified playlist item for background service
class _PlaylistItem {
  final String projectId;
  final String displayName;
  final String? fileName;
  final String? previewSongPath;

  _PlaylistItem(MusicProject project)
      : projectId = project.id,
        displayName = project.displayName,
        fileName = project.previewSongFileName,
        previewSongPath = project.previewSongPath;
}