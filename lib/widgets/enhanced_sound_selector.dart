import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/enhanced_timer_provider.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../services/soundscape_download_service.dart';

class EnhancedSoundSelector extends StatefulWidget {
  const EnhancedSoundSelector({super.key});

  @override
  State<EnhancedSoundSelector> createState() => _EnhancedSoundSelectorState();
}

class _EnhancedSoundSelectorState extends State<EnhancedSoundSelector> with TickerProviderStateMixin {
  String _selectedTrackId = 'forest_rain';
  double _volume = 0.5;
  late TabController _tabController;
  late SoundscapeDownloadService _downloadService;

  @override
  void initState() {
    super.initState();
    _downloadService = SoundscapeDownloadService();
    _downloadService.initialize();
    _tabController = TabController(length: 4, vsync: this);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final selectedSound = StorageService.selectedSound;
    final audioService = AudioService();
    
    // Try to find track by name for backward compatibility
    final track = audioService.availableTracks.firstWhere(
      (t) => t.name == selectedSound,
      orElse: () => audioService.availableTracks.first,
    );
    
    setState(() {
      _selectedTrackId = track.id;
      _volume = StorageService.soundVolume;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedTimerProvider>(
      builder: (context, timerProvider, child) {
        final audioService = timerProvider.audioService;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.waves,
                        color: Theme.of(context).primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ambient Soundscapes',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Professional audio for focus',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Current track status
                    if (audioService.isPlaying)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_circle_fill, color: Colors.green, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Playing',
                              style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // Category tabs
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                  indicatorColor: Theme.of(context).primaryColor,
                  tabs: const [
                    Tab(text: 'Nature', icon: Icon(Icons.forest, size: 20)),
                    Tab(text: 'Ambient', icon: Icon(Icons.blur_on, size: 20)),
                    Tab(text: 'Urban', icon: Icon(Icons.location_city, size: 20)),
                    Tab(text: 'Fireplace', icon: Icon(Icons.whatshot, size: 20)),
                  ],
                ),

                const SizedBox(height: 20),

                // Track selection
                SizedBox(
                  height: 280,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTrackGrid(audioService, SoundscapeCategory.nature),
                      _buildTrackGrid(audioService, SoundscapeCategory.ambient),
                      _buildTrackGrid(audioService, SoundscapeCategory.urban),
                      _buildTrackGrid(audioService, SoundscapeCategory.fireplace),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Volume and fade controls
                _buildAudioControls(audioService),

                const SizedBox(height: 20),

                // Playback controls
                _buildPlaybackControls(audioService),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrackGrid(AudioService audioService, SoundscapeCategory category) {
    final tracks = audioService.getTracksByCategory(category);
    
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        final isSelected = _selectedTrackId == track.id;
        final isCurrentPlaying = audioService.currentTrackId == track.id && audioService.isPlaying;
        
        return GestureDetector(
          onTap: () async {
            setState(() {
              _selectedTrackId = track.id;
            });
            await StorageService.setSelectedSound(track.name);
            
            if (audioService.isPlaying) {
              await audioService.playTrack(track.id);
            }
          },
          child: ChangeNotifierProvider.value(
            value: _downloadService,
            child: Consumer<SoundscapeDownloadService>(
              builder: (context, downloadService, child) {
                final download = downloadService.getDownload(track.id);
                final isDownloaded = download?.status == DownloadStatus.downloaded;
                final isDownloading = download?.status == DownloadStatus.downloading;
                
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).dividerColor,
                      width: isSelected ? 2 : 1,
                    ),
                    color: isSelected 
                        ? Theme.of(context).primaryColor.withOpacity(0.05)
                        : null,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                track.name,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCurrentPlaying)
                              const Icon(Icons.play_circle_fill, color: Colors.green, size: 20)
                            else if (isDownloading)
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: download?.progress,
                                ),
                              )
                            else if (isDownloaded)
                              const Icon(Icons.download_done, color: Colors.blue, size: 20)
                            else
                              GestureDetector(
                                onTap: () => downloadService.downloadTrack(track.id),
                                child: const Icon(Icons.download, color: Colors.grey, size: 20),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          track.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        if (isDownloading && download != null)
                          LinearProgressIndicator(
                            value: download.progress,
                            backgroundColor: Colors.grey.withOpacity(0.3),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAudioControls(AudioService audioService) {
    return Column(
      children: [
        // Volume control
        Row(
          children: [
            Icon(Icons.volume_down, color: Theme.of(context).primaryColor),
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
                activeColor: Theme.of(context).primaryColor,
              ),
            ),
            Icon(Icons.volume_up, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              '${(_volume * 100).round()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        
        // Fade controls
        Row(
          children: [
            Icon(Icons.tune, color: Theme.of(context).primaryColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Fade: ${audioService.fadeInDuration.inSeconds}s in, ${audioService.fadeOutDuration.inSeconds}s out',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            TextButton(
              onPressed: () => _showFadeSettings(audioService),
              child: const Text('Adjust'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaybackControls(AudioService audioService) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              if (audioService.isPlaying) {
                await audioService.stopTrack();
              } else {
                await audioService.playTrack(_selectedTrackId);
              }
            },
            icon: Icon(
              audioService.isPlaying ? Icons.stop : Icons.play_arrow,
            ),
            label: Text(audioService.isPlaying ? 'Stop' : 'Play'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (audioService.isPlaying)
          ElevatedButton.icon(
            onPressed: () async {
              await audioService.pauseTrack(withFadeOut: true);
            },
            icon: const Icon(Icons.pause),
            label: const Text('Pause'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
      ],
    );
  }

  void _showFadeSettings(AudioService audioService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fade Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Customize fade in/out durations'),
            const SizedBox(height: 16),
            Text('Fade In: ${audioService.fadeInDuration.inSeconds}s'),
            Text('Fade Out: ${audioService.fadeOutDuration.inSeconds}s'),
            const SizedBox(height: 16),
            const Text('Adjust fade settings for smoother transitions'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}