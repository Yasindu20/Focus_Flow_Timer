import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_goals.dart';

class GoalSettingDialog extends StatefulWidget {
  final UserGoals? currentGoals;
  final Function(UserGoals) onGoalsUpdated;

  const GoalSettingDialog({
    super.key,
    this.currentGoals,
    required this.onGoalsUpdated,
  });

  @override
  State<GoalSettingDialog> createState() => _GoalSettingDialogState();
}

class _GoalSettingDialogState extends State<GoalSettingDialog> {
  late TextEditingController _dailySessionsController;
  late TextEditingController _weeklyHoursController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dailySessionsController = TextEditingController(
      text: (widget.currentGoals?.dailySessions ?? 4).toString(),
    );
    _weeklyHoursController = TextEditingController(
      text: (widget.currentGoals?.weeklyHours ?? 20).toString(),
    );
  }

  @override
  void dispose() {
    _dailySessionsController.dispose();
    _weeklyHoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Your Goals'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            const Text(
              'Set personalized targets to track your progress and stay motivated.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _dailySessionsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Daily Sessions Target',
                hintText: 'e.g., 4',
                prefixIcon: Icon(Icons.today),
                border: OutlineInputBorder(),
                helperText: 'Number of focus sessions per day',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a daily session target';
                }
                final sessions = int.tryParse(value);
                if (sessions == null || sessions < 1 || sessions > 20) {
                  return 'Please enter a number between 1 and 20';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weeklyHoursController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Weekly Hours Target',
                hintText: 'e.g., 20',
                prefixIcon: Icon(Icons.schedule),
                border: OutlineInputBorder(),
                helperText: 'Total focus hours per week',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a weekly hours target';
                }
                final hours = int.tryParse(value);
                if (hours == null || hours < 1 || hours > 100) {
                  return 'Please enter a number between 1 and 100';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildRecommendations(),
            ],
          ),
        ),
      ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveGoals,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Goals'),
        ),
      ],
    );
  }

  Widget _buildRecommendations() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Recommendations',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• Start with 4-6 sessions per day (2-3 hours)',
            style: TextStyle(fontSize: 12),
          ),
          const Text(
            '• Aim for 15-25 hours per week initially',
            style: TextStyle(fontSize: 12),
          ),
          const Text(
            '• Gradually increase as you build consistency',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _saveGoals() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final goals = UserGoals(
        userId: userId,
        dailySessions: int.parse(_dailySessionsController.text),
        weeklyHours: int.parse(_weeklyHoursController.text),
      );

      widget.onGoalsUpdated(goals);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Goals updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save goals: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}