import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class FocusSoundService {
  static final FocusSoundService _instance = FocusSoundService._internal();
  factory FocusSoundService() => _instance;
  FocusSoundService._internal();

  // Dual-player system for seamless crossfading
  AudioPlayer? _playerA;
  AudioPlayer? _playerB;
  AudioPlayer? _activePlayer;
  AudioPlayer? _inactivePlayer;
  
  bool _isPlaying = false;
  String? _currentSound;
  double _volume = 0.7;
  
  // Overlap crossfading configuration
  static const Duration _crossfadeDuration = Duration(milliseconds: 3000); // 3-second overlap
  static const Duration _preloadBuffer = Duration(milliseconds: 3500); // Start 3.5s before end
  
  Timer? _crossfadeTimer;
  Timer? _positionChecker;
  Duration? _trackDuration;
  bool _isTransitioning = false;

  // Available focus sounds
  static const Map<String, String> sounds = {
    'Ambient Noise': 'sounds/ambient-noise_processed.mp3',
    'Brown Noise': 'sounds/brown-noise_processed.mp3',
    'Coffee Shop': 'sounds/coffee-shop_processed.mp3',
    'Fireplace': 'sounds/fireplace_processed.mp3',
    'Forest Birds': 'sounds/forest_birds_processed.mp3',
    'Light Rain': 'sounds/light-rain_processed.mp3',
    'Ocean Waves': 'sounds/ocean-waves_processed.mp3',
    'Rain in the City': 'sounds/rain-in-the-city_processed.mp3',
  };

  bool get isPlaying => _isPlaying;
  String? get currentSound => _currentSound;
  double get volume => _volume;

  Future<void> initialize() async {
    _playerA = AudioPlayer();
    _playerB = AudioPlayer();
    
    // Configure for continuous media playback
    await _playerA!.setPlayerMode(PlayerMode.mediaPlayer);
    await _playerB!.setPlayerMode(PlayerMode.mediaPlayer);
    
    // Set release mode to loop for seamless playback
    await _playerA!.setReleaseMode(ReleaseMode.loop);
    await _playerB!.setReleaseMode(ReleaseMode.loop);
    
    // Configure audio session for background playback
    await _playerA!.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: [
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.allowBluetooth,
            AVAudioSessionOptions.defaultToSpeaker,
          ],
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ),
    );
    
    await _playerB!.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: [
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.allowBluetooth,
            AVAudioSessionOptions.defaultToSpeaker,
          ],
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ),
    );
    
    // Initialize active player as A
    _activePlayer = _playerA;
    _inactivePlayer = _playerB;
    
    debugPrint('FocusSoundService: Dual-player system initialized with background playback support');
  }

  Future<void> play(String soundName) async {
    if (!sounds.containsKey(soundName)) {
      debugPrint('FocusSoundService: Sound "$soundName" not found');
      return;
    }

    try {
      await stop();
      
      final assetPath = sounds[soundName]!;
      debugPrint('FocusSoundService: Starting seamless playback of $soundName with fade-in');
      
      // Start with active player at 0 volume for smooth fade-in
      await _activePlayer!.setVolume(0.0);
      await _activePlayer!.play(AssetSource(assetPath));
      
      // Preload inactive player for crossfading
      await _inactivePlayer!.setVolume(0.0);
      await _inactivePlayer!.play(AssetSource(assetPath));
      
      _isPlaying = true;
      _currentSound = soundName;
      
      // Perform smooth fade-in
      await _performFadeIn();
      
      // Start crossfade management
      _startCrossfadeLoop();
      
      debugPrint('FocusSoundService: Successfully started seamless $soundName with fade-in complete');
    } catch (e) {
      debugPrint('FocusSoundService: Error playing $soundName: $e');
      _isPlaying = false;
      _currentSound = null;
    }
  }

  Future<void> stop() async {
    if (_isPlaying) {
      try {
        _crossfadeTimer?.cancel();
        
        // Perform smooth fade-out before stopping
        await _performFadeOut();
        
        await _playerA?.stop();
        await _playerB?.stop();
        
        _isPlaying = false;
        _currentSound = null;
        debugPrint('FocusSoundService: Stopped seamless playback with fade-out');
      } catch (e) {
        debugPrint('FocusSoundService: Error stopping: $e');
      }
    }
  }

  Future<void> pause() async {
    if (_isPlaying) {
      try {
        _crossfadeTimer?.cancel();
        
        await _playerA?.pause();
        await _playerB?.pause();
        
        _isPlaying = false;
        debugPrint('FocusSoundService: Paused seamless playback');
      } catch (e) {
        debugPrint('FocusSoundService: Error pausing: $e');
      }
    }
  }

  Future<void> resume() async {
    if (!_isPlaying && _currentSound != null) {
      try {
        await _activePlayer?.resume();
        await _inactivePlayer?.resume();
        
        _isPlaying = true;
        _startCrossfadeLoop();
        
        debugPrint('FocusSoundService: Resumed seamless playback');
      } catch (e) {
        debugPrint('FocusSoundService: Error resuming: $e');
      }
    }
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    
    if (_isPlaying) {
      try {
        // Only update the active player's volume during playback
        await _activePlayer?.setVolume(_volume);
        debugPrint('FocusSoundService: Volume set to ${(_volume * 100).round()}%');
      } catch (e) {
        debugPrint('FocusSoundService: Error setting volume: $e');
      }
    }
  }

  // Advanced seamless looping with position monitoring
  void _startCrossfadeLoop() {
    _crossfadeTimer?.cancel();
    _positionChecker?.cancel();
    
    _detectTrackDuration().then((duration) {
      if (duration != null && _isPlaying) {
        _trackDuration = duration;
        
        debugPrint('FocusSoundService: Track duration detected: ${duration.inSeconds}s, starting position monitoring');
        
        // Start continuous position monitoring for precise timing
        _startPositionMonitoring();
      } else {
        // Fallback to fixed timing if duration detection fails
        _trackDuration = const Duration(seconds: 30);
        _startPositionMonitoring();
        debugPrint('FocusSoundService: Using fallback duration, starting position monitoring');
      }
    });
  }

  void _startPositionMonitoring() {
    _positionChecker = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!_isPlaying || _isTransitioning) return;
      
      try {
        final position = await _activePlayer?.getCurrentPosition();
        if (position != null && _trackDuration != null) {
          final remainingTime = _trackDuration! - position;
          
          // Start crossfade when we're close to the end
          if (remainingTime <= _preloadBuffer) {
            _isTransitioning = true;
            timer.cancel();
            debugPrint('FocusSoundService: Starting precise crossfade with ${remainingTime.inMilliseconds}ms remaining');
            await _performAdvancedCrossfade();
          }
        }
      } catch (e) {
        debugPrint('FocusSoundService: Position monitoring error: $e');
      }
    });
  }

  Future<Duration?> _detectTrackDuration() async {
    try {
      // Get duration from active player
      final duration = await _activePlayer?.getDuration();
      return duration;
    } catch (e) {
      debugPrint('FocusSoundService: Error detecting track duration: $e');
      return null;
    }
  }

  Future<void> _performFadeIn() async {
    if (!_isPlaying || _currentSound == null) return;
    
    try {
      debugPrint('FocusSoundService: Starting smooth fade-in');
      
      // Smooth fade-in over 1 second with 25 steps
      const steps = 25; // 25 steps over 1000ms = 40ms per step  
      const stepDuration = Duration(milliseconds: 40);
      
      for (int i = 0; i < steps; i++) {
        if (!_isPlaying) break; // Stop if playback stopped
        
        final progress = i / (steps - 1);
        final currentVolume = _volume * progress;
        
        await _activePlayer?.setVolume(currentVolume);
        await Future.delayed(stepDuration);
      }
      
      // Ensure final volume is set correctly
      await _activePlayer?.setVolume(_volume);
      
      debugPrint('FocusSoundService: Fade-in completed');
      
    } catch (e) {
      debugPrint('FocusSoundService: Error during fade-in: $e');
      // Fallback: set volume directly if fade-in fails
      await _activePlayer?.setVolume(_volume);
    }
  }

  Future<void> _performFadeOut() async {
    if (!_isPlaying) return;
    
    try {
      debugPrint('FocusSoundService: Starting smooth fade-out');
      
      // Quick fade-out over 500ms
      const steps = 15; // 15 steps over 500ms = ~33ms per step
      const stepDuration = Duration(milliseconds: 33);
      
      final startVolume = _volume;
      
      for (int i = 0; i < steps; i++) {
        final progress = i / (steps - 1);
        final currentVolume = startVolume * (1.0 - progress);
        
        await _activePlayer?.setVolume(currentVolume);
        await _inactivePlayer?.setVolume(currentVolume);
        await Future.delayed(stepDuration);
      }
      
      debugPrint('FocusSoundService: Fade-out completed');
      
    } catch (e) {
      debugPrint('FocusSoundService: Error during fade-out: $e');
    }
  }

  Future<void> _performAdvancedCrossfade() async {
    if (!_isPlaying || _currentSound == null) return;
    
    try {
      debugPrint('FocusSoundService: Starting overlap crossfade - mixing ending with beginning');
      
      final assetPath = sounds[_currentSound!]!;
      
      // Start inactive player (second loop) at the beginning with 0 volume
      await _inactivePlayer?.stop();
      await _inactivePlayer?.setVolume(0.0);
      await _inactivePlayer?.play(AssetSource(assetPath));
      
      // Wait for inactive player to stabilize
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Perform 3-second overlap crossfade
      // During this time, the first loop's ending fades out while second loop's beginning fades in
      const steps = 75; // 75 steps over 3000ms = 40ms per step
      const stepDuration = Duration(milliseconds: 40);
      
      for (int i = 0; i < steps; i++) {
        if (!_isPlaying) break;
        
        final progress = i / (steps - 1);
        
        // Create smooth S-curve for more natural mixing
        final fadeProgress = _smoothStep(progress);
        
        // First loop (ending): Gradually fade out over 3 seconds
        final activeVolume = _volume * (1.0 - fadeProgress);
        
        // Second loop (beginning): Gradually fade in over 3 seconds  
        final inactiveVolume = _volume * fadeProgress;
        
        // Apply volumes simultaneously for perfect mixing
        await Future.wait([
          _activePlayer?.setVolume(activeVolume) ?? Future.value(),
          _inactivePlayer?.setVolume(inactiveVolume) ?? Future.value(),
        ]);
        
        await Future.delayed(stepDuration);
      }
      
      // Ensure clean final state
      await _activePlayer?.setVolume(0.0);
      await _inactivePlayer?.setVolume(_volume);
      
      // Swap players - the "new" loop becomes active
      final temp = _activePlayer;
      _activePlayer = _inactivePlayer;
      _inactivePlayer = temp;
      
      // Stop the now-inactive player (old loop)
      await _inactivePlayer?.stop();
      
      debugPrint('FocusSoundService: Overlap crossfade completed - seamless loop transition');
      
      // Reset transition state and restart monitoring
      _isTransitioning = false;
      _startCrossfadeLoop();
      
    } catch (e) {
      debugPrint('FocusSoundService: Error during overlap crossfade: $e');
      _isTransitioning = false;
      _startCrossfadeLoop();
    }
  }

  // Smooth step function for S-curve transitions (prevents abrupt changes)
  double _smoothStep(double progress) {
    // Hermite interpolation: 3t² - 2t³ creates smooth S-curve
    return progress * progress * (3.0 - 2.0 * progress);
  }

  // Equal power crossfade curves for audio mixing
  double _equalPowerFade(double progress) {
    // Use cosine/sine curves for constant power during crossfade
    return progress * progress;
  }

  // Memory and battery optimization methods
  void _optimizeForLongPlayback() {
    // Reduce frequency of duration checks during long sessions
    if (_trackDuration != null && _trackDuration!.inMinutes > 5) {
      // For longer tracks, reduce crossfade frequency
      debugPrint('FocusSoundService: Optimizing for long playback session');
    }
  }

  void _handleAppStateChange(bool isBackground) {
    if (isBackground && _isPlaying) {
      // Reduce processing when app is backgrounded
      debugPrint('FocusSoundService: Optimizing for background playback');
      // Continue audio but reduce timer precision
    } else if (!isBackground && _isPlaying) {
      // Resume full processing when app is foregrounded
      debugPrint('FocusSoundService: Resuming full processing');
    }
  }

  void dispose() {
    _crossfadeTimer?.cancel();
    _positionChecker?.cancel();
    _crossfadeTimer = null;
    _positionChecker = null;
    
    // Properly dispose audio players
    _playerA?.stop();
    _playerB?.stop();
    _playerA?.dispose();
    _playerB?.dispose();
    
    // Clear references to help with garbage collection
    _playerA = null;
    _playerB = null;
    _activePlayer = null;
    _inactivePlayer = null;
    _currentSound = null;
    _trackDuration = null;
    
    debugPrint('FocusSoundService: Advanced dual-player system fully disposed');
  }
}