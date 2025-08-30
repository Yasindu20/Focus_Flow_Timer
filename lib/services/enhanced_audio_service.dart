import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enhanced Audio Service with ambient sounds, AI-generated audio, and focus-optimized soundscapes
class EnhancedAudioService {
  static final EnhancedAudioService _instance = EnhancedAudioService._internal();
  factory EnhancedAudioService() => _instance;
  EnhancedAudioService._internal();

  // Audio players
  final AudioPlayer _primaryPlayer = AudioPlayer();
  final AudioPlayer _secondaryPlayer = AudioPlayer();
  final AudioPlayer _effectsPlayer = AudioPlayer();

  // State management
  bool _isPlaying = false;
  double _volume = 0.7;
  FocusSoundProfile? _currentProfile;
  Timer? _fadeTimer;
  Timer? _layerTimer;
  
  // Cache and storage
  final Map<String, String> _soundCache = {};
  static const String _volumeKey = 'enhanced_audio_volume';
  static const String _profileKey = 'focus_sound_profile';

  // Ambient sound collections
  static const String _freesoundApiKey = ''; // You'll need to get this from freesound.org
  
  // Built-in procedural sounds
  late ProceduralSoundGenerator _soundGenerator;

  // Getters
  bool get isPlaying => _isPlaying;
  double get volume => _volume;
  FocusSoundProfile? get currentProfile => _currentProfile;

  /// Initialize the enhanced audio service
  Future<void> initialize() async {
    await _loadSettings();
    _soundGenerator = ProceduralSoundGenerator();
    
    // Configure audio players
    await _configureAudioPlayers();
    
    if (kDebugMode) {
      print('🎵 Enhanced Audio Service initialized');
      print('   Volume: $_volume');
      print('   Current Profile: ${_currentProfile?.name ?? "None"}');
    }
  }

  /// Get all available sound profiles
  List<FocusSoundProfile> getAvailableProfiles() {
    return [
      // Built-in procedural sounds
      FocusSoundProfile(
        id: 'white_noise',
        name: 'White Noise',
        description: 'Pure white noise for maximum focus',
        type: FocusSoundType.procedural,
        icon: '🌊',
        category: FocusSoundCategory.noise,
        focusIntensity: 0.9,
        isUnlocked: true,
      ),
      FocusSoundProfile(
        id: 'brown_noise',
        name: 'Brown Noise',
        description: 'Deep, warm brown noise for concentration',
        type: FocusSoundType.procedural,
        icon: '🏔️',
        category: FocusSoundCategory.noise,
        focusIntensity: 0.85,
        isUnlocked: true,
      ),
      FocusSoundProfile(
        id: 'pink_noise',
        name: 'Pink Noise',
        description: 'Balanced pink noise for relaxed focus',
        type: FocusSoundType.procedural,
        icon: '🌸',
        category: FocusSoundCategory.noise,
        focusIntensity: 0.8,
        isUnlocked: true,
      ),
      
      // Nature sounds (procedural)
      FocusSoundProfile(
        id: 'rain_gentle',
        name: 'Gentle Rain',
        description: 'Soft raindrops for peaceful focus',
        type: FocusSoundType.procedural,
        icon: '🌧️',
        category: FocusSoundCategory.nature,
        focusIntensity: 0.75,
        isUnlocked: true,
      ),
      FocusSoundProfile(
        id: 'forest_ambient',
        name: 'Forest Ambience',
        description: 'Birds and rustling leaves',
        type: FocusSoundType.procedural,
        icon: '🌲',
        category: FocusSoundCategory.nature,
        focusIntensity: 0.7,
        isUnlocked: true,
      ),
      FocusSoundProfile(
        id: 'ocean_waves',
        name: 'Ocean Waves',
        description: 'Rhythmic ocean waves',
        type: FocusSoundType.procedural,
        icon: '🌊',
        category: FocusSoundCategory.nature,
        focusIntensity: 0.8,
        isUnlocked: true,
      ),
      
      // Coffee shop / ambient
      FocusSoundProfile(
        id: 'coffee_shop',
        name: 'Coffee Shop',
        description: 'Gentle chatter and ambient café sounds',
        type: FocusSoundType.procedural,
        icon: '☕',
        category: FocusSoundCategory.ambient,
        focusIntensity: 0.65,
        isUnlocked: false, // Unlock with achievements
      ),
      FocusSoundProfile(
        id: 'library',
        name: 'Library',
        description: 'Quiet library atmosphere',
        type: FocusSoundType.procedural,
        icon: '📚',
        category: FocusSoundCategory.ambient,
        focusIntensity: 0.9,
        isUnlocked: false,
      ),
      
      // Binaural beats for focus
      FocusSoundProfile(
        id: 'focus_beats_40hz',
        name: 'Focus Beats (40Hz)',
        description: 'Gamma waves for intense focus',
        type: FocusSoundType.binaural,
        icon: '🧠',
        category: FocusSoundCategory.binaural,
        focusIntensity: 0.95,
        isUnlocked: false, // Premium feature
      ),
      FocusSoundProfile(
        id: 'alpha_waves',
        name: 'Alpha Waves (10Hz)',
        description: 'Relaxed awareness and creativity',
        type: FocusSoundType.binaural,
        icon: '✨',
        category: FocusSoundCategory.binaural,
        focusIntensity: 0.7,
        isUnlocked: false,
      ),
      
      // Adaptive soundscapes
      FocusSoundProfile(
        id: 'adaptive_focus',
        name: 'Adaptive Focus',
        description: 'AI-powered soundscape that adapts to your focus',
        type: FocusSoundType.adaptive,
        icon: '🤖',
        category: FocusSoundCategory.adaptive,
        focusIntensity: 0.9,
        isUnlocked: false,
      ),
    ];
  }

  /// Start playing a focus sound profile
  Future<bool> playProfile(FocusSoundProfile profile) async {
    try {
      if (_isPlaying) {
        await stopPlayback();
      }

      _currentProfile = profile;
      
      switch (profile.type) {
        case FocusSoundType.procedural:
          await _playProceduralSound(profile);
          break;
        case FocusSoundType.online:
          await _playOnlineSound(profile);
          break;
        case FocusSoundType.binaural:
          await _playBinauralBeats(profile);
          break;
        case FocusSoundType.adaptive:
          await _playAdaptiveSound(profile);
          break;
      }

      _isPlaying = true;
      await _saveSettings();
      
      if (kDebugMode) print('🎵 Started playing: ${profile.name}');
      return true;

    } catch (e) {
      if (kDebugMode) print('❌ Failed to play sound: $e');
      return false;
    }
  }

  /// Stop all audio playback
  Future<void> stopPlayback() async {
    try {
      await _primaryPlayer.stop();
      await _secondaryPlayer.stop();
      await _effectsPlayer.stop();
      
      _fadeTimer?.cancel();
      _layerTimer?.cancel();
      
      _isPlaying = false;
      _currentProfile = null;
      
      if (kDebugMode) print('🔇 Audio playback stopped');
    } catch (e) {
      if (kDebugMode) print('❌ Error stopping playback: $e');
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    
    await _primaryPlayer.setVolume(_volume);
    await _secondaryPlayer.setVolume(_volume * 0.8); // Secondary layer slightly quieter
    await _effectsPlayer.setVolume(_volume * 0.6); // Effects even quieter
    
    await _saveSettings();
    
    if (kDebugMode) print('🔊 Volume set to: $_volume');
  }

  /// Create a custom layered soundscape
  Future<void> createCustomSoundscape({
    required List<FocusSoundProfile> layers,
    required String name,
    List<double>? layerVolumes,
  }) async {
    // This would allow users to mix multiple sounds
    // Implementation would involve multiple audio players
  }

  /// Unlock sound profile (for gamification)
  Future<void> unlockProfile(String profileId) async {
    final profiles = getAvailableProfiles();
    final profile = profiles.firstWhere((p) => p.id == profileId);
    profile.isUnlocked = true;
    
    // Save unlock state to preferences
    final prefs = await SharedPreferences.getInstance();
    final unlockedProfiles = prefs.getStringList('unlocked_profiles') ?? [];
    if (!unlockedProfiles.contains(profileId)) {
      unlockedProfiles.add(profileId);
      await prefs.setStringList('unlocked_profiles', unlockedProfiles);
    }
  }

  // Private methods

  Future<void> _configureAudioPlayers() async {
    // Configure primary player (main sound)
    await _primaryPlayer.setReleaseMode(ReleaseMode.loop);
    await _primaryPlayer.setVolume(_volume);
    
    // Configure secondary player (layered sounds)
    await _secondaryPlayer.setReleaseMode(ReleaseMode.loop);
    await _secondaryPlayer.setVolume(_volume * 0.8);
    
    // Configure effects player (one-time effects)
    await _effectsPlayer.setVolume(_volume * 0.6);
  }

  Future<void> _playProceduralSound(FocusSoundProfile profile) async {
    final audioData = _soundGenerator.generateSound(profile);
    
    // Save generated audio to temporary file
    final tempDir = await getTemporaryDirectory();
    final audioFile = File('${tempDir.path}/${profile.id}_generated.wav');
    await audioFile.writeAsBytes(audioData);
    
    // Play the generated sound
    await _primaryPlayer.play(DeviceFileSource(audioFile.path));
    
    // Add subtle variations every few minutes to prevent habituation
    _startVariationTimer(profile);
  }

  Future<void> _playOnlineSound(FocusSoundProfile profile) async {
    // This would fetch sounds from free APIs like Freesound.org
    // For now, we'll use a placeholder implementation
    
    if (_freesoundApiKey.isEmpty) {
      // Fallback to procedural generation
      await _playProceduralSound(profile);
      return;
    }
    
    // Fetch sound from cache or download
    String? soundUrl = _soundCache[profile.id];
    if (soundUrl == null) {
      soundUrl = await _fetchSoundFromAPI(profile);
      if (soundUrl != null) {
        _soundCache[profile.id] = soundUrl;
      }
    }
    
    if (soundUrl != null) {
      await _primaryPlayer.play(UrlSource(soundUrl));
    } else {
      // Fallback to procedural
      await _playProceduralSound(profile);
    }
  }

  Future<void> _playBinauralBeats(FocusSoundProfile profile) async {
    // Generate binaural beats
    final leftFreq = _getBinauralBaseFrequency(profile);
    // final rightFreq = leftFreq + _getBinauralBeatFrequency(profile);
    
    // Generate binaural beats (simplified implementation)
    // final leftData = _soundGenerator.generateTone(leftFreq, 60.0);
    // final rightData = _soundGenerator.generateTone(rightFreq, 60.0);
    
    // This would require stereo audio generation
    // For now, use a simplified approach
    await _playProceduralSound(profile);
  }

  Future<void> _playAdaptiveSound(FocusSoundProfile profile) async {
    // AI-powered adaptive soundscape
    // This would analyze user's focus patterns and adjust the soundscape
    
    // For now, start with a base sound and add adaptive layers
    await _playProceduralSound(profile);
    
    // Start adaptive behavior
    _startAdaptiveBehavior(profile);
  }

  Future<String?> _fetchSoundFromAPI(FocusSoundProfile profile) async {
    if (_freesoundApiKey.isEmpty) return null;
    
    try {
      // Freesound.org API example
      final query = _getSearchQuery(profile);
      final response = await http.get(
        Uri.parse('https://freesound.org/apiv2/search/text/?query=$query&token=$_freesoundApiKey&format=json&fields=id,name,previews'),
      );
      
      if (response.statusCode == 200) {
        // Parse response and get preview URL
        // This is a simplified implementation
        return null; // Would return actual URL
      }
    } catch (e) {
      if (kDebugMode) print('❌ API fetch failed: $e');
    }
    return null;
  }

  String _getSearchQuery(FocusSoundProfile profile) {
    switch (profile.category) {
      case FocusSoundCategory.nature:
        return profile.id.replaceAll('_', ' ');
      case FocusSoundCategory.noise:
        return '${profile.id} noise';
      case FocusSoundCategory.ambient:
        return '${profile.id} ambient';
      default:
        return profile.name;
    }
  }

  double _getBinauralBaseFrequency(FocusSoundProfile profile) {
    switch (profile.id) {
      case 'focus_beats_40hz':
        return 200.0; // Base frequency
      case 'alpha_waves':
        return 150.0;
      default:
        return 180.0;
    }
  }

  double _getBinauralBeatFrequency(FocusSoundProfile profile) {
    switch (profile.id) {
      case 'focus_beats_40hz':
        return 40.0; // Gamma waves
      case 'alpha_waves':
        return 10.0; // Alpha waves
      default:
        return 20.0;
    }
  }

  void _startVariationTimer(FocusSoundProfile profile) {
    _layerTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (!_isPlaying || _currentProfile?.id != profile.id) {
        timer.cancel();
        return;
      }
      
      // Add subtle variations to prevent habituation
      _addSubtleVariation();
    });
  }

  void _startAdaptiveBehavior(FocusSoundProfile profile) {
    // This would analyze user behavior and adapt the soundscape
    // For now, add periodic subtle changes
    _layerTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
      if (!_isPlaying || _currentProfile?.id != profile.id) {
        timer.cancel();
        return;
      }
      
      _adaptSoundscape();
    });
  }

  Future<void> _addSubtleVariation() async {
    // Add a subtle layer or modify existing sound slightly
    final random = Random();
    
    if (random.nextDouble() < 0.3) { // 30% chance of adding variation
      // Add a subtle nature sound layer
      final variationVolume = _volume * 0.2; // Very quiet
      await _effectsPlayer.setVolume(variationVolume);
      
      // This would play a short sound effect
      // For now, just log the variation
      if (kDebugMode) print('🎵 Added subtle sound variation');
    }
  }

  Future<void> _adaptSoundscape() async {
    // This would use AI to adapt the soundscape based on:
    // - Time of day
    // - Focus session progress  
    // - User's historical preferences
    // - Environmental factors (weather API)
    
    if (kDebugMode) print('🤖 Adapting soundscape for better focus');
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _volume = prefs.getDouble(_volumeKey) ?? 0.7;
    
    final profileId = prefs.getString(_profileKey);
    if (profileId != null) {
      final profiles = getAvailableProfiles();
      _currentProfile = profiles.firstWhere(
        (p) => p.id == profileId,
        orElse: () => profiles.first,
      );
    }
    
    // Load unlocked profiles
    final unlockedProfiles = prefs.getStringList('unlocked_profiles') ?? [];
    final profiles = getAvailableProfiles();
    for (final profileId in unlockedProfiles) {
      final profile = profiles.firstWhere((p) => p.id == profileId, orElse: () => profiles.first);
      profile.isUnlocked = true;
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_volumeKey, _volume);
    if (_currentProfile != null) {
      await prefs.setString(_profileKey, _currentProfile!.id);
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stopPlayback();
    await _primaryPlayer.dispose();
    await _secondaryPlayer.dispose();
    await _effectsPlayer.dispose();
    _fadeTimer?.cancel();
    _layerTimer?.cancel();
  }
}

/// Procedural sound generator for creating ambient sounds
class ProceduralSoundGenerator {
  final Random _random = Random();

  /// Generate audio data for a focus sound profile
  List<int> generateSound(FocusSoundProfile profile) {
    switch (profile.id) {
      case 'white_noise':
        return _generateWhiteNoise(60); // 60 seconds
      case 'brown_noise':
        return _generateBrownNoise(60);
      case 'pink_noise':
        return _generatePinkNoise(60);
      case 'rain_gentle':
        return _generateRainSound(60);
      case 'forest_ambient':
        return _generateForestSound(60);
      case 'ocean_waves':
        return _generateOceanWaves(60);
      default:
        return _generateWhiteNoise(60);
    }
  }

  /// Generate a pure tone for binaural beats
  List<int> generateTone(double frequency, double durationSeconds) {
    const int sampleRate = 44100;
    final int numSamples = (sampleRate * durationSeconds).round();
    final List<int> samples = [];
    
    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double sample = sin(2 * pi * frequency * t) * 0.5;
      samples.add((sample * 32767).round());
    }
    
    return samples;
  }

  List<int> _generateWhiteNoise(int durationSeconds) {
    const int sampleRate = 44100;
    final int numSamples = sampleRate * durationSeconds;
    final List<int> samples = [];
    
    for (int i = 0; i < numSamples; i++) {
      final double sample = (_random.nextDouble() - 0.5) * 0.3;
      samples.add((sample * 32767).round());
    }
    
    return samples;
  }

  List<int> _generateBrownNoise(int durationSeconds) {
    const int sampleRate = 44100;
    final int numSamples = sampleRate * durationSeconds;
    final List<int> samples = [];
    double previousSample = 0.0;
    
    for (int i = 0; i < numSamples; i++) {
      final double white = _random.nextDouble() - 0.5;
      previousSample = (previousSample + white * 0.02).clamp(-1.0, 1.0);
      samples.add((previousSample * 32767 * 0.3).round());
    }
    
    return samples;
  }

  List<int> _generatePinkNoise(int durationSeconds) {
    // Simplified pink noise implementation
    return _generateBrownNoise(durationSeconds);
  }

  List<int> _generateRainSound(int durationSeconds) {
    const int sampleRate = 44100;
    final int numSamples = sampleRate * durationSeconds;
    final List<int> samples = [];
    
    for (int i = 0; i < numSamples; i++) {
      // Base noise
      double sample = (_random.nextDouble() - 0.5) * 0.1;
      
      // Add occasional droplet sounds
      if (_random.nextDouble() < 0.001) { // Rare droplets
        final double droplet = sin(2 * pi * (800 + _random.nextDouble() * 400) * i / sampleRate) 
                              * exp(-i * 0.001) * 0.3;
        sample += droplet;
      }
      
      samples.add((sample * 32767).round());
    }
    
    return samples;
  }

  List<int> _generateForestSound(int durationSeconds) {
    const int sampleRate = 44100;
    final int numSamples = sampleRate * durationSeconds;
    final List<int> samples = [];
    
    for (int i = 0; i < numSamples; i++) {
      // Base ambient noise
      double sample = (_random.nextDouble() - 0.5) * 0.05;
      
      // Add occasional bird sounds
      if (_random.nextDouble() < 0.0005) { // Very rare birds
        final double bird = sin(2 * pi * (1000 + _random.nextDouble() * 2000) * i / sampleRate) 
                           * exp(-i * 0.002) * 0.2;
        sample += bird;
      }
      
      // Add wind rustling
      if (i % 1000 < 100) {
        sample += (_random.nextDouble() - 0.5) * 0.02;
      }
      
      samples.add((sample * 32767).round());
    }
    
    return samples;
  }

  List<int> _generateOceanWaves(int durationSeconds) {
    const int sampleRate = 44100;
    final int numSamples = sampleRate * durationSeconds;
    final List<int> samples = [];
    
    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      
      // Main wave sound (low frequency)
      double sample = sin(2 * pi * 0.1 * t) * 0.3;
      
      // Add wave crashes
      sample += sin(2 * pi * 0.05 * t) * sin(2 * pi * 50 * t) * 0.1;
      
      // Add background noise
      sample += (_random.nextDouble() - 0.5) * 0.05;
      
      samples.add((sample * 32767).round());
    }
    
    return samples;
  }
}

// Data classes for sound profiles

enum FocusSoundType { procedural, online, binaural, adaptive }

enum FocusSoundCategory { nature, noise, ambient, binaural, adaptive }

class FocusSoundProfile {
  final String id;
  final String name;
  final String description;
  final FocusSoundType type;
  final String icon;
  final FocusSoundCategory category;
  final double focusIntensity; // 0.0 to 1.0
  bool isUnlocked;
  
  FocusSoundProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.icon,
    required this.category,
    required this.focusIntensity,
    this.isUnlocked = false,
  });
}