import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/enhanced_timer_provider.dart';
import '../services/optimized_storage_service.dart';
import '../services/focus_sound_service.dart';
import '../core/constants/colors.dart';

class SoundSelector extends StatefulWidget {
  const SoundSelector({super.key});

  @override
  State<SoundSelector> createState() => _SoundSelectorState();
}

class _SoundSelectorState extends State<SoundSelector> {
  String _selectedSound = 'None';
  double _volume = 0.7;
  final OptimizedStorageService _storage = OptimizedStorageService();
  final FocusSoundService _soundService = FocusSoundService();

  final List<Map<String, dynamic>> _availableSounds = [
    {
      'name': 'None',
      'icon': Icons.volume_off_rounded,
      'description': 'Silent focus',
      'color': AppColors.textTertiary,
    },
    {
      'name': 'Light Rain',
      'icon': Icons.water_drop_rounded,
      'description': 'Gentle raindrops',
      'color': AppColors.accentMint,
    },
    {
      'name': 'Forest Birds',
      'icon': Icons.forest_rounded,
      'description': 'Nature sounds',
      'color': AppColors.restfulGreen,
    },
    {
      'name': 'Ocean Waves',
      'icon': Icons.waves_rounded,
      'description': 'Ocean waves',
      'color': AppColors.primaryBlue,
    },
    {
      'name': 'Brown Noise',
      'icon': Icons.graphic_eq_rounded,
      'description': 'Deep focus',
      'color': AppColors.textSecondary,
    },
    {
      'name': 'Coffee Shop',
      'icon': Icons.local_cafe_rounded,
      'description': 'Cafe ambiance',
      'color': const Color(0xFF8B4513),
    },
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

  Future<void> _loadSettings() async {
    try {
      final settings = await _storage.getCachedData('sound_settings');
      if (settings != null && mounted) {
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
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;
    final isSmallScreen = screenHeight < 700;
    
    return Consumer<EnhancedTimerProvider>(
      builder: (context, timerProvider, child) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: isMobile ? (screenWidth < 400 ? 0 : 4) : 8),
          padding: EdgeInsets.all(isMobile ? (screenWidth < 400 ? 12 : 16) : 20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon - more compact on mobile
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 6 : 8),
                    decoration: BoxDecoration(
                      color: AppColors.accentMint.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.music_note_rounded,
                      color: AppColors.accentMint,
                      size: isMobile ? 16 : 18,
                    ),
                  ),
                  SizedBox(width: isMobile ? 8 : 12),
                  Flexible(
                    child: Text(
                      'Focus Sounds',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: isMobile ? 16 : 18,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 12 : 16),
              
              // Sound selection grid
              _buildSoundGrid(isMobile, isSmallScreen),
              
              // Volume control (only show when sound is selected)
              if (_selectedSound != 'None') ...[
                SizedBox(height: isMobile ? 12 : 16),
                _buildVolumeControl(isMobile),
              ],
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildSoundGrid(bool isMobile, bool isSmallScreen) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = isMobile && screenWidth < 400 ? 2 : 3;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: isMobile ? 6 : 8,
            mainAxisSpacing: isMobile ? 6 : 8,
            childAspectRatio: isMobile && screenWidth < 400 ? 1.15 : (isMobile ? 0.95 : 1.1),
          ),
          itemCount: _availableSounds.length,
          itemBuilder: (context, index) {
            final sound = _availableSounds[index];
            final isSelected = _selectedSound == sound['name'];
            
            return _buildSoundCard(
              name: sound['name'],
              icon: sound['icon'],
              description: sound['description'],
              color: sound['color'],
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedSound = sound['name'];
                });
                _saveSoundSettings();
              },
            );
          },
        );
      },
    );
  }
  
  Widget _buildSoundCard({
    required String name,
    required IconData icon,
    required String description,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: '$name sound',
      hint: isSelected ? 'Currently selected' : 'Tap to select $description',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.1)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? color.withValues(alpha: 0.3)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  flex: 2,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.15)
                          : color.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? color : color.withValues(alpha: 0.7),
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  flex: 1,
                  child: Text(
                    name,
                    style: TextStyle(
                      color: isSelected ? color : AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 8,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildVolumeControl(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.volume_up_rounded,
                size: isMobile ? 14 : 16,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: isMobile ? 6 : 8),
              Flexible(
                child: Text(
                  'Volume',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: isMobile ? 12 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 6 : 8,
                  vertical: isMobile ? 2 : 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentMint.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(_volume * 100).round()}%',
                  style: TextStyle(
                    color: AppColors.accentMint,
                    fontSize: isMobile ? 10 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Row(
            children: [
              Icon(
                Icons.volume_down_rounded,
                size: isMobile ? 14 : 16,
                color: AppColors.textTertiary,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.accentMint,
                    inactiveTrackColor: AppColors.progressTrack,
                    thumbColor: AppColors.accentMint,
                    overlayColor: AppColors.accentMint.withValues(alpha: 0.1),
                    trackHeight: isMobile ? 3 : 4,
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: isMobile ? 6 : 8,
                    ),
                  ),
                  child: Slider(
                    value: _volume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
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
              ),
              Icon(
                Icons.volume_up_rounded,
                size: isMobile ? 14 : 16,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _soundService.dispose();
    super.dispose();
  }
}