import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/enhanced_timer_provider.dart';
import '../services/optimized_storage_service.dart';

class EnhancedSoundSelector extends StatefulWidget {
  const EnhancedSoundSelector({super.key});

  @override
  State<EnhancedSoundSelector> createState() => _EnhancedSoundSelectorState();
}

class _EnhancedSoundSelectorState extends State<EnhancedSoundSelector> {
  String _selectedSound = 'None';
  double _volume = 0.5;
  final OptimizedStorageService _storage = OptimizedStorageService();

  // Basic sound options for free version
  final List<Map<String, dynamic>> _availableSounds = [
    {'id': 'none', 'name': 'None', 'icon': Icons.volume_off, 'description': 'No background sound'},
    {'id': 'rain', 'name': 'Rain', 'icon': Icons.water_drop, 'description': 'Gentle rain sounds'},
    {'id': 'forest', 'name': 'Forest', 'icon': Icons.forest, 'description': 'Nature forest ambiance'},
    {'id': 'ocean', 'name': 'Ocean', 'icon': Icons.waves, 'description': 'Ocean waves'},
    {'id': 'cafe', 'name': 'Café', 'icon': Icons.local_cafe, 'description': 'Coffee shop ambiance'},
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
                    Icon(
                      Icons.audiotrack,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Background Sounds',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Sound Options
                Text(
                  'Choose a background sound:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                
                const SizedBox(height: 16),
                
                // Sound Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = MediaQuery.of(context).size.width < 600;
                    final isSmallMobile = MediaQuery.of(context).size.width < 400;
                    
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isSmallMobile ? 1 : 2,
                        childAspectRatio: isSmallMobile ? 3.0 : (isMobile ? 2.2 : 2.5),
                        crossAxisSpacing: isSmallMobile ? 6 : 12,
                        mainAxisSpacing: isSmallMobile ? 6 : 12,
                      ),
                      itemCount: _availableSounds.length,
                      itemBuilder: (context, index) {
                        final sound = _availableSounds[index];
                        final isSelected = _selectedSound == sound['name'];
                        
                        return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedSound = sound['name'];
                        });
                        _saveSoundSettings();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
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
                                      fontWeight: isSelected 
                                          ? FontWeight.bold 
                                          : FontWeight.normal,
                                      color: isSelected 
                                          ? Theme.of(context).primaryColor
                                          : null,
                                    ),
                                  ),
                                  Text(
                                    sound['description'],
                                    style: TextStyle(
                                      fontSize: 10,
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
                    );
                  },
                ),
                
                if (_selectedSound != 'None') ...[
                  const SizedBox(height: 24),
                  
                  // Volume Control
                  Text(
                    'Volume',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  
                  const SizedBox(height: 8),
                  
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
                          onChangeEnd: (value) {
                            _saveSoundSettings();
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
                
                const SizedBox(height: 16),
                
                // Info Note
                Container(
                  padding: const EdgeInsets.all(12),
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
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
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