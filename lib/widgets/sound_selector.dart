import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/enhanced_timer_provider.dart';
import '../services/optimized_storage_service.dart';

class SoundSelector extends StatefulWidget {
  const SoundSelector({super.key});

  @override
  State<SoundSelector> createState() => _SoundSelectorState();
}

class _SoundSelectorState extends State<SoundSelector> {
  String _selectedSound = 'None';
  double _volume = 0.5;
  final OptimizedStorageService _storage = OptimizedStorageService();

  final List<String> _availableSounds = [
    'None',
    'Rain',
    'Forest',
    'Ocean',
    'White Noise',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _storage.getCachedData('sound_settings');
      if (settings != null) {
        setState(() {
          _selectedSound = settings['selectedSound'] ?? 'None';
          _volume = (settings['volume'] ?? 0.5).toDouble();
        });
      }
    } catch (e) {
      debugPrint('Error loading sound settings: $e');
    }
  }

  Future<void> _saveSoundSettings() async {
    try {
      await _storage.cacheData('sound_settings', {
        'selectedSound': _selectedSound,
        'volume': _volume,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving sound settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedTimerProvider>(
      builder: (context, timerProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Background Sound',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                
                // Sound Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedSound,
                  decoration: const InputDecoration(
                    labelText: 'Select Sound',
                    border: OutlineInputBorder(),
                  ),
                  items: _availableSounds.map((sound) {
                    return DropdownMenuItem(
                      value: sound,
                      child: Text(sound),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedSound = value;
                      });
                      _saveSoundSettings();
                    }
                  },
                ),
                
                if (_selectedSound != 'None') ...[
                  const SizedBox(height: 16),
                  
                  // Volume Slider
                  Row(
                    children: [
                      const Icon(Icons.volume_down),
                      Expanded(
                        child: Slider(
                          value: _volume,
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
                          label: '${(_volume * 100).round()}%',
                          onChanged: (value) {
                            setState(() {
                              _volume = value;
                            });
                          },
                          onChangeEnd: (value) {
                            _saveSoundSettings();
                          },
                        ),
                      ),
                      const Icon(Icons.volume_up),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}