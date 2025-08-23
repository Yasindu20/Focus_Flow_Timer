import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import 'advanced_timer_service.dart';

enum SoundscapeCategory {
  nature,
  ambient,
  urban,
  fireplace
}

class SoundscapeTrack {
  final String id;
  final String name;
  final String path;
  final SoundscapeCategory category;
  final String description;
  final bool isDownloaded;
  final int durationSeconds;

  const SoundscapeTrack({
    required this.id,
    required this.name,
    required this.path,
    required this.category,
    required this.description,
    this.isDownloaded = true,
    this.durationSeconds = 0,
  });
}

class AudioService extends ChangeNotifier {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _effectPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _currentTrackId;
  double _volume = 0.5;
  bool _isFading = false;
  Duration _fadeInDuration = const Duration(seconds: 2);
  Duration _fadeOutDuration = const Duration(seconds: 2);

  // Getters
  bool get isPlaying => _isPlaying;
  String? get currentTrackId => _currentTrackId;
  double get volume => _volume;
  bool get isFading => _isFading;
  Duration get fadeInDuration => _fadeInDuration;
  Duration get fadeOutDuration => _fadeOutDuration;
  
  List<SoundscapeTrack> get availableTracks => _soundscapeTracks;
  SoundscapeTrack? get currentTrack => _currentTrackId != null 
      ? _soundscapeTracks.firstWhere((t) => t.id == _currentTrackId, 
          orElse: () => _soundscapeTracks.first)
      : null;

  // Enhanced soundscape tracks
  static const List<SoundscapeTrack> _soundscapeTracks = [
    SoundscapeTrack(
      id: 'forest_rain',
      name: 'Forest Rain',
      path: 'assets/sounds/forest_rain.mp3',
      category: SoundscapeCategory.nature,
      description: 'Gentle rain falling through forest leaves with distant bird calls',
      durationSeconds: 1800,
    ),
    SoundscapeTrack(
      id: 'white_noise',
      name: 'White Noise',
      path: 'assets/sounds/white_noise.mp3',
      category: SoundscapeCategory.ambient,
      description: 'Pure white noise for deep focus and concentration',
      durationSeconds: 1800,
    ),
    SoundscapeTrack(
      id: 'brown_noise',
      name: 'Brown Noise',
      path: 'assets/sounds/brown_noise.mp3',
      category: SoundscapeCategory.ambient,
      description: 'Deeper brown noise for relaxation and stress relief',
      durationSeconds: 1800,
    ),
    SoundscapeTrack(
      id: 'coffee_shop',
      name: 'Coffee Shop',
      path: 'assets/sounds/coffee_shop.mp3',
      category: SoundscapeCategory.urban,
      description: 'Cozy coffee shop ambiance with gentle chatter and brewing sounds',
      durationSeconds: 1800,
    ),
    SoundscapeTrack(
      id: 'ocean_waves',
      name: 'Ocean Waves',
      path: 'assets/sounds/ocean_waves.mp3',
      category: SoundscapeCategory.nature,
      description: 'Rhythmic ocean waves on a peaceful shore',
      durationSeconds: 1800,
    ),
    SoundscapeTrack(
      id: 'city_rain',
      name: 'City Rain',
      path: 'assets/sounds/city_rain.mp3',
      category: SoundscapeCategory.urban,
      description: 'Rain falling on city streets with distant traffic',
      durationSeconds: 1800,
    ),
    SoundscapeTrack(
      id: 'fireplace',
      name: 'Fireplace',
      path: 'assets/sounds/fireplace.mp3',
      category: SoundscapeCategory.fireplace,
      description: 'Crackling fireplace with gentle wood burning sounds',
      durationSeconds: 1800,
    ),
    SoundscapeTrack(
      id: 'forest_birds',
      name: 'Forest Birds',
      path: 'assets/sounds/forest_birds.mp3',
      category: SoundscapeCategory.nature,
      description: 'Peaceful forest with chirping birds and rustling leaves',
      durationSeconds: 1800,
    ),
  ];

  // Enhanced audio controls with fade effects
  Future<void> playTrack(String trackId, {bool withFadeIn = true}) async {
    try {
      if (_currentTrackId == trackId && _isPlaying) {
        return; // Already playing this track
      }

      final track = _soundscapeTracks.firstWhere(
        (t) => t.id == trackId,
        orElse: () => _soundscapeTracks.first,
      );

      if (withFadeIn && _isPlaying) {
        await _fadeOut();
      } else {
        await _audioPlayer.stop();
      }

      await _audioPlayer.play(
        AssetSource(track.path.replaceFirst('assets/', '')),
      );
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      
      _currentTrackId = trackId;
      _isPlaying = true;
      
      if (withFadeIn) {
        await _fadeIn();
      } else {
        await _audioPlayer.setVolume(_volume);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing track: $e');
    }
  }

  Future<void> _fadeIn() async {
    if (_isFading) return;
    _isFading = true;
    
    const steps = 20;
    final stepDuration = _fadeInDuration.inMilliseconds ~/ steps;
    final volumeStep = _volume / steps;
    
    await _audioPlayer.setVolume(0);
    
    for (int i = 1; i <= steps; i++) {
      if (!_isPlaying) break;
      await Future.delayed(Duration(milliseconds: stepDuration));
      await _audioPlayer.setVolume(volumeStep * i);
    }
    
    _isFading = false;
    notifyListeners();
  }

  Future<void> _fadeOut() async {
    if (_isFading || !_isPlaying) return;
    _isFading = true;
    
    const steps = 20;
    final stepDuration = _fadeOutDuration.inMilliseconds ~/ steps;
    final currentVolume = _volume;
    final volumeStep = currentVolume / steps;
    
    for (int i = steps; i > 0; i--) {
      if (!_isPlaying) break;
      await Future.delayed(Duration(milliseconds: stepDuration));
      await _audioPlayer.setVolume(volumeStep * i);
    }
    
    await _audioPlayer.stop();
    _isFading = false;
    notifyListeners();
  }

  Future<void> stopTrack({bool withFadeOut = true}) async {
    try {
      if (withFadeOut && _isPlaying) {
        await _fadeOut();
      } else {
        await _audioPlayer.stop();
      }
      _isPlaying = false;
      _currentTrackId = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping track: $e');
    }
  }

  Future<void> pauseTrack({bool withFadeOut = false}) async {
    try {
      if (withFadeOut) {
        await _fadeOut();
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.pause();
      }
      _isPlaying = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error pausing track: $e');
    }
  }

  Future<void> resumeTrack({bool withFadeIn = false}) async {
    try {
      await _audioPlayer.resume();
      _isPlaying = true;
      
      if (withFadeIn) {
        await _fadeIn();
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error resuming track: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      _volume = volume.clamp(0.0, 1.0);
      if (!_isFading) {
        await _audioPlayer.setVolume(_volume);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  // Fade configuration
  void setFadeDurations({
    Duration? fadeIn,
    Duration? fadeOut,
  }) {
    if (fadeIn != null) _fadeInDuration = fadeIn;
    if (fadeOut != null) _fadeOutDuration = fadeOut;
    notifyListeners();
  }

  // Track filtering by category
  List<SoundscapeTrack> getTracksByCategory(SoundscapeCategory category) {
    return _soundscapeTracks.where((track) => track.category == category).toList();
  }

  // Legacy compatibility method
  List<String> get availableTrackNames => _soundscapeTracks.map((t) => t.name).toList();
  
  Future<void> playTrackByName(String trackName) async {
    final track = _soundscapeTracks.firstWhere(
      (t) => t.name == trackName,
      orElse: () => _soundscapeTracks.first,
    );
    await playTrack(track.id);
  }

  // Add this method for completion sounds
  Future<void> playCompletionSound(TimerType timerType) async {
    try {
      String soundPath;
      switch (timerType) {
        case TimerType.work:
          soundPath = 'sounds/completion/work_complete.mp3';
          break;
        case TimerType.shortBreak:
          soundPath = 'sounds/completion/break_complete.mp3';
          break;
        case TimerType.longBreak:
          soundPath = 'sounds/completion/long_break_complete.mp3';
          break;
        case TimerType.custom:
          soundPath = 'sounds/completion/custom_complete.mp3';
          break;
      }

      await _effectPlayer.play(AssetSource(soundPath));
      await _effectPlayer.setVolume(0.8); // Slightly lower volume for completion sounds
    } catch (e) {
      debugPrint('Error playing completion sound: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _effectPlayer.dispose();
    super.dispose();
  }
}
