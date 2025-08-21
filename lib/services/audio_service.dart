import 'package:audioplayers/audioplayers.dart';
import '../core/constants/app_constants.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _currentTrack;
  double _volume = 0.5;

  // Getters
  bool get isPlaying => _isPlaying;
  String? get currentTrack => _currentTrack;
  double get volume => _volume;
  List<String> get availableTracks => AppConstants.soundTracks.keys.toList();

  // Audio controls
  Future<void> playTrack(String trackName) async {
    try {
      if (_currentTrack == trackName && _isPlaying) {
        return; // Already playing this track
      }

      await stopTrack();

      final trackPath = AppConstants.soundTracks[trackName];
      if (trackPath != null) {
        await _audioPlayer.play(
          AssetSource(trackPath.replaceFirst('assets/', '')),
        );
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer.setVolume(_volume);

        _currentTrack = trackName;
        _isPlaying = true;
      }
    } catch (e) {
      print('Error playing track: $e');
    }
  }

  Future<void> stopTrack() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      _currentTrack = null;
    } catch (e) {
      print('Error stopping track: $e');
    }
  }

  Future<void> pauseTrack() async {
    try {
      await _audioPlayer.pause();
      _isPlaying = false;
    } catch (e) {
      print('Error pausing track: $e');
    }
  }

  Future<void> resumeTrack() async {
    try {
      await _audioPlayer.resume();
      _isPlaying = true;
    } catch (e) {
      print('Error resuming track: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      _volume = volume.clamp(0.0, 1.0);
      await _audioPlayer.setVolume(_volume);
    } catch (e) {
      print('Error setting volume: $e');
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
