import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'audio_service.dart';

enum DownloadStatus {
  notDownloaded,
  downloading,
  downloaded,
  error,
}

class SoundscapeDownload {
  final String trackId;
  final DownloadStatus status;
  final double progress;
  final String? localPath;
  final DateTime? downloadDate;
  final String? errorMessage;

  const SoundscapeDownload({
    required this.trackId,
    required this.status,
    this.progress = 0.0,
    this.localPath,
    this.downloadDate,
    this.errorMessage,
  });

  SoundscapeDownload copyWith({
    DownloadStatus? status,
    double? progress,
    String? localPath,
    DateTime? downloadDate,
    String? errorMessage,
  }) {
    return SoundscapeDownload(
      trackId: trackId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      localPath: localPath ?? this.localPath,
      downloadDate: downloadDate ?? this.downloadDate,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SoundscapeDownloadService extends ChangeNotifier {
  static final SoundscapeDownloadService _instance = SoundscapeDownloadService._internal();
  factory SoundscapeDownloadService() => _instance;
  SoundscapeDownloadService._internal();

  final Map<String, SoundscapeDownload> _downloads = {};
  late Directory _localDirectory;
  bool _initialized = false;

  // Getters
  Map<String, SoundscapeDownload> get downloads => Map.unmodifiable(_downloads);
  bool get isInitialized => _initialized;

  SoundscapeDownload? getDownload(String trackId) => _downloads[trackId];
  
  bool isDownloaded(String trackId) {
    return _downloads[trackId]?.status == DownloadStatus.downloaded;
  }

  bool isDownloading(String trackId) {
    return _downloads[trackId]?.status == DownloadStatus.downloading;
  }

  double getDownloadProgress(String trackId) {
    return _downloads[trackId]?.progress ?? 0.0;
  }

  // Initialize service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _localDirectory = await getApplicationDocumentsDirectory();
      final soundsDir = Directory('${_localDirectory.path}/sounds');
      if (!await soundsDir.exists()) {
        await soundsDir.create(recursive: true);
      }

      await _loadDownloadStatus();
      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing SoundscapeDownloadService: $e');
    }
  }

  // Load download status from preferences
  Future<void> _loadDownloadStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final audioService = AudioService();
      
      for (final track in audioService.availableTracks) {
        final isDownloaded = prefs.getBool('downloaded_${track.id}') ?? false;
        final localPath = prefs.getString('path_${track.id}');
        final downloadDateStr = prefs.getString('date_${track.id}');
        
        DateTime? downloadDate;
        if (downloadDateStr != null) {
          downloadDate = DateTime.tryParse(downloadDateStr);
        }

        if (isDownloaded && localPath != null) {
          final file = File(localPath);
          if (await file.exists()) {
            _downloads[track.id] = SoundscapeDownload(
              trackId: track.id,
              status: DownloadStatus.downloaded,
              progress: 1.0,
              localPath: localPath,
              downloadDate: downloadDate,
            );
          } else {
            // File was deleted, update preferences
            await _clearDownloadStatus(track.id);
            _downloads[track.id] = SoundscapeDownload(
              trackId: track.id,
              status: DownloadStatus.notDownloaded,
            );
          }
        } else {
          _downloads[track.id] = SoundscapeDownload(
            trackId: track.id,
            status: DownloadStatus.notDownloaded,
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading download status: $e');
    }
  }

  // Download a soundscape track
  Future<void> downloadTrack(String trackId) async {
    if (!_initialized) await initialize();
    
    final audioService = AudioService();
    final track = audioService.availableTracks.firstWhere(
      (t) => t.id == trackId,
      orElse: () => throw ArgumentError('Track not found: $trackId'),
    );

    if (isDownloaded(trackId) || isDownloading(trackId)) {
      return;
    }

    try {
      // Update status to downloading
      _downloads[trackId] = SoundscapeDownload(
        trackId: trackId,
        status: DownloadStatus.downloading,
        progress: 0.0,
      );
      notifyListeners();

      // Simulate download progress (in a real app, this would be actual HTTP download)
      final localPath = '${_localDirectory.path}/sounds/${track.id}.mp3';
      
      // For demo purposes, simulate downloading by creating a placeholder file
      // In production, you would download from a CDN or streaming service
      await _simulateDownload(trackId, localPath);

      // Save download status
      await _saveDownloadStatus(trackId, localPath);

      _downloads[trackId] = SoundscapeDownload(
        trackId: trackId,
        status: DownloadStatus.downloaded,
        progress: 1.0,
        localPath: localPath,
        downloadDate: DateTime.now(),
      );
      
      notifyListeners();
      
    } catch (e) {
      _downloads[trackId] = SoundscapeDownload(
        trackId: trackId,
        status: DownloadStatus.error,
        errorMessage: e.toString(),
      );
      notifyListeners();
      debugPrint('Error downloading track $trackId: $e');
    }
  }

  // Simulate download with progress updates
  Future<void> _simulateDownload(String trackId, String localPath) async {
    const steps = 10;
    const stepDelay = Duration(milliseconds: 200);
    
    for (int i = 1; i <= steps; i++) {
      await Future.delayed(stepDelay);
      
      _downloads[trackId] = _downloads[trackId]!.copyWith(
        progress: i / steps,
      );
      notifyListeners();
    }
    
    // Create placeholder file (in production, write actual audio data)
    final file = File(localPath);
    await file.writeAsString('placeholder_audio_data_for_${trackId}');
  }

  // Delete downloaded track
  Future<void> deleteTrack(String trackId) async {
    if (!isDownloaded(trackId)) return;

    try {
      final download = _downloads[trackId];
      if (download?.localPath != null) {
        final file = File(download!.localPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      await _clearDownloadStatus(trackId);
      
      _downloads[trackId] = SoundscapeDownload(
        trackId: trackId,
        status: DownloadStatus.notDownloaded,
      );
      
      notifyListeners();
      
    } catch (e) {
      debugPrint('Error deleting track $trackId: $e');
    }
  }

  // Delete all downloaded tracks
  Future<void> deleteAllTracks() async {
    final downloadedTracks = _downloads.entries
        .where((entry) => entry.value.status == DownloadStatus.downloaded)
        .map((entry) => entry.key)
        .toList();

    for (final trackId in downloadedTracks) {
      await deleteTrack(trackId);
    }
  }

  // Get total storage used by downloads
  Future<int> getTotalStorageUsed() async {
    int totalBytes = 0;
    
    for (final download in _downloads.values) {
      if (download.status == DownloadStatus.downloaded && download.localPath != null) {
        try {
          final file = File(download.localPath!);
          if (await file.exists()) {
            final stat = await file.stat();
            totalBytes += stat.size;
          }
        } catch (e) {
          debugPrint('Error getting file size: $e');
        }
      }
    }
    
    return totalBytes;
  }

  // Save download status to preferences
  Future<void> _saveDownloadStatus(String trackId, String localPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('downloaded_$trackId', true);
      await prefs.setString('path_$trackId', localPath);
      await prefs.setString('date_$trackId', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error saving download status: $e');
    }
  }

  // Clear download status from preferences
  Future<void> _clearDownloadStatus(String trackId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('downloaded_$trackId');
      await prefs.remove('path_$trackId');
      await prefs.remove('date_$trackId');
    } catch (e) {
      debugPrint('Error clearing download status: $e');
    }
  }

  // Format bytes to human readable string
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}