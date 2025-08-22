import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/enhanced_timer_provider.dart';
import '../services/storage_service.dart';

class SoundSelector extends StatefulWidget {
  const SoundSelector({Key? key}) : super(key: key);

  @override
  State<SoundSelector> createState() => _SoundSelectorState();
}

class _SoundSelectorState extends State<SoundSelector> {
  String _selectedSound = 'Forest Rain';
  double _volume = 0.5;

  @override
  void initState() {
    super.initState();
    _selectedSound = StorageService.selectedSound;
    _volume = StorageService.soundVolume;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerProvider>(
      builder: (context, timerProvider, child) {
        final audioService = timerProvider.audioService;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.music_note),
                    const SizedBox(width: 8),
                    Text(
                      'Ambient Sounds',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Sound selection
                ...audioService.availableTracks.map((track) {
                  return RadioListTile<String>(
                    title: Text(track),
                    value: track,
                    groupValue: _selectedSound,
                    onChanged: (value) async {
                      if (value != null) {
                        setState(() {
                          _selectedSound = value;
                        });
                        await StorageService.setSelectedSound(value);

                        if (audioService.isPlaying) {
                          await audioService.playTrack(value);
                        }
                      }
                    },
                  );
                }).toList(),

                const SizedBox(height: 16),

                // Volume control
                Row(
                  children: [
                    const Icon(Icons.volume_down),
                    Expanded(
                      child: Slider(
                        value: _volume,
                        onChanged: (value) async {
                          setState(() {
                            _volume = value;
                          });
                          await audioService.setVolume(value);
                          await StorageService.setSoundVolume(value);
                        },
                      ),
                    ),
                    const Icon(Icons.volume_up),
                  ],
                ),

                const SizedBox(height: 16),

                // Play/Stop button
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (audioService.isPlaying) {
                        await audioService.stopTrack();
                      } else {
                        await audioService.playTrack(_selectedSound);
                      }
                      setState(() {});
                    },
                    icon: Icon(
                      audioService.isPlaying ? Icons.stop : Icons.play_arrow,
                    ),
                    label: Text(audioService.isPlaying ? 'Stop' : 'Play'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
