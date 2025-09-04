import 'package:flutter/material.dart';
import '../services/focus_sound_service.dart';

class FocusSoundControls extends StatefulWidget {
  const FocusSoundControls({super.key});

  @override
  State<FocusSoundControls> createState() => _FocusSoundControlsState();
}

class _FocusSoundControlsState extends State<FocusSoundControls> {
  final FocusSoundService _soundService = FocusSoundService();
  String _selectedSound = 'None';
  double _volume = 0.7;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _soundService.initialize();
    setState(() {
      _selectedSound = _soundService.currentSound ?? 'None';
      _volume = _soundService.volume;
      _isPlaying = _soundService.isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.headset, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Focus Sounds',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Sound selector
            DropdownButtonFormField<String>(
              value: _selectedSound,
              decoration: const InputDecoration(
                labelText: 'Background Sound',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: 'None', child: Text('None')),
                ...FocusSoundService.sounds.keys.map(
                  (sound) => DropdownMenuItem(value: sound, child: Text(sound)),
                ),
              ],
              onChanged: (String? newSound) async {
                if (newSound != null) {
                  setState(() {
                    _selectedSound = newSound;
                  });
                  
                  if (newSound == 'None') {
                    await _soundService.stop();
                    setState(() {
                      _isPlaying = false;
                    });
                  } else {
                    await _soundService.play(newSound);
                    setState(() {
                      _isPlaying = true;
                    });
                  }
                }
              },
            ),
            
            if (_selectedSound != 'None') ...[
              const SizedBox(height: 16),
              
              // Play/Pause controls
              Row(
                children: [
                  IconButton(
                    onPressed: () async {
                      if (_isPlaying) {
                        await _soundService.pause();
                        setState(() {
                          _isPlaying = false;
                        });
                      } else {
                        await _soundService.resume();
                        setState(() {
                          _isPlaying = true;
                        });
                      }
                    },
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  ),
                  
                  IconButton(
                    onPressed: () async {
                      await _soundService.stop();
                      setState(() {
                        _selectedSound = 'None';
                        _isPlaying = false;
                      });
                    },
                    icon: const Icon(Icons.stop),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Volume control
                  const Icon(Icons.volume_down, size: 20),
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
                        _soundService.setVolume(value);
                      },
                    ),
                  ),
                  const Icon(Icons.volume_up, size: 20),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _soundService.dispose();
    super.dispose();
  }
}