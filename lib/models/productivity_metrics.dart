// Additional productivity metrics and classes
class TaskEfficiency {
  final double estimationAccuracy;
  final double focusScore;
  final double completionRate;
  final Duration averageTimePerTask;

  TaskEfficiency({
    required this.estimationAccuracy,
    required this.focusScore,
    required this.completionRate,
    required this.averageTimePerTask,
  });
}

class WorkingTimeAnalysis {
  final Map<int, double> productivityByHour;
  final Map<int, double> productivityByDay;
  final List<int> optimalWorkingHours;
  final int mostProductiveDay;

  WorkingTimeAnalysis({
    required this.productivityByHour,
    required this.productivityByDay,
    required this.optimalWorkingHours,
    required this.mostProductiveDay,
  });
}
