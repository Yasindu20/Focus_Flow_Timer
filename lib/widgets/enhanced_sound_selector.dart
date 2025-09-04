import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/enhanced_timer_provider.dart';
import '../services/optimized_storage_service.dart';
import '../services/focus_sound_service.dart';

class EnhancedSoundSelector extends StatefulWidget {
  const EnhancedSoundSelector({super.key});

  @override
  State<EnhancedSoundSelector> createState() => _EnhancedSoundSelectorState();
}

class _EnhancedSoundSelectorState extends State<EnhancedSoundSelector> {
  String _selectedSound = 'None';
  double _volume = 0.7;
  final OptimizedStorageService _storage = OptimizedStorageService();
  final FocusSoundService _soundService = FocusSoundService();

  // Available white noise sounds
  final List<Map<String, dynamic>> _availableSounds = [
    {'id': 'none', 'name': 'None', 'icon': Icons.volume_off, 'description': 'No background sound'},
    {'id': 'ambient', 'name': 'Ambient Noise', 'icon': Icons.blur_on, 'description': 'Ambient white noise'},
    {'id': 'brown', 'name': 'Brown Noise', 'icon': Icons.waves, 'description': 'Deep brown noise'},
    {'id': 'coffee', 'name': 'Coffee Shop', 'icon': Icons.local_cafe, 'description': 'Coffee shop ambiance'},
    {'id': 'fireplace', 'name': 'Fireplace', 'icon': Icons.local_fire_department, 'description': 'Crackling fireplace'},
    {'id': 'forest', 'name': 'Forest Birds', 'icon': Icons.forest, 'description': 'Forest birds chirping'},
    {'id': 'rain', 'name': 'Light Rain', 'icon': Icons.water_drop, 'description': 'Gentle rain sounds'},
    {'id': 'ocean', 'name': 'Ocean Waves', 'icon': Icons.waves, 'description': 'Ocean waves'},
    {'id': 'city_rain', 'name': 'Rain in the City', 'icon': Icons.location_city, 'description': 'Urban rain sounds'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeService();
    _loadSettings();
  }
  
  Future<void> _initializeService() async {
    await _soundService.initialize();
  }

  @override
  void dispose() {
    _soundService.dispose();
    super.dispose();
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
      
      // Apply audio changes
      await _soundService.setVolume(_volume);
      if (_selectedSound != 'None') {
        await _soundService.play(_selectedSound);
      } else {
        await _soundService.stop();
      }
    } catch (e) {
      debugPrint('Error saving sound settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 400;
    final padding = isSmallMobile ? 12.0 : (isMobile ? 16.0 : 20.0);
    
    return Consumer<EnhancedTimerProvider>(
      builder: (context, timerProvider, child) {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: isSmallMobile ? 320 : (isMobile ? 380 : 420),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.audiotrack,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                    SizedBox(width: isSmallMobile ? 8 : 12),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Background Sounds',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallMobile ? 18 : null,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: isSmallMobile ? 12 : 16),
                
                // Sound Options
                Text(
                  'Choose a background sound:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                
                SizedBox(height: isSmallMobile ? 10 : 12),
                
                // Sound Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallMobile = MediaQuery.of(context).size.width < 400;
                    
                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: isSmallMobile ? 180 : 220, // Reduced max height 
                      ),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(), // Allow scrolling if needed
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isSmallMobile ? 1 : 2,
                          childAspectRatio: isSmallMobile ? 4.0 : 3.5, // Better ratios
                          crossAxisSpacing: isSmallMobile ? 8 : 12,
                          mainAxisSpacing: isSmallMobile ? 8 : 12,
                        ),
                        itemCount: _availableSounds.length,
                      itemBuilder: (context, index) {
                        final sound = _availableSounds[index];
                        final isSelected = _selectedSound == sound['name'];
                        
                        return GestureDetector(
                      onTap: () async {
                        setState(() {
                          _selectedSound = sound['name'];
                        });
                        await _saveSoundSettings();
                      },
                      child: Container(
                        padding: EdgeInsets.all(isSmallMobile ? 8 : 12),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected 
                                ? Theme.of(context).primaryColor
                                : Colors.grey.withValues(alpha: 0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              sound['icon'],
                              color: isSelected 
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    sound['name'],
                                    style: TextStyle(
                                      fontSize: isSmallMobile ? 12 : 14,
                                      fontWeight: isSelected 
                                          ? FontWeight.bold 
                                          : FontWeight.normal,
                                      color: isSelected 
                                          ? Theme.of(context).primaryColor
                                          : null,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    sound['description'],
                                    style: TextStyle(
                                      fontSize: isSmallMobile ? 9 : 10,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                        );
                      },
                      ),
                    );
                  },
                ),
                
                if (_selectedSound != 'None') ...[
                  SizedBox(height: isSmallMobile ? 16 : 20),
                  
                  // Volume Control
                  Text(
                    'Volume',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  
                  SizedBox(height: isSmallMobile ? 6 : 8),
                  
                  Row(
                    children: [
                      Icon(
                        Icons.volume_down,
                        color: Colors.grey[600],
                        size: 20,
                      ),
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
                          onChangeEnd: (value) async {
                            await _saveSoundSettings();
                          },
                        ),
                      ),
                      Icon(
                        Icons.volume_up,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ],
                  ),
                ],
                
                SizedBox(height: isSmallMobile ? 12 : 16),
                
                // Info Note
                Container(
                  padding: EdgeInsets.all(isSmallMobile ? 8 : 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Background sounds help maintain focus during timer sessions.',
                          style: TextStyle(
                            fontSize: isSmallMobile ? 11 : 12,
                            color: Colors.blue[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}