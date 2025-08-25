import 'package:cloud_firestore/cloud_firestore.dart';

class SessionAnalytics {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final String status; // 'completed' | 'interrupted'

  SessionAnalytics({
    required this.id,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.durationMinutes,
    required this.status,
  });

  factory SessionAnalytics.fromFirestore(Map<String, dynamic> data, String id) {
    return SessionAnalytics(
      id: id,
      userId: data['userId'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null ? (data['endTime'] as Timestamp).toDate() : null,
      durationMinutes: data['durationMinutes'] ?? 0,
      status: data['status'] ?? 'interrupted',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'durationMinutes': durationMinutes,
      'status': status,
    };
  }

  bool get isCompleted => status == 'completed';
  bool get isInterrupted => status == 'interrupted';
}