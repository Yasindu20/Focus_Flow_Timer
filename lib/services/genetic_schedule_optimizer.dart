import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/enhanced_task.dart';
import '../models/ai_insights.dart';

/// Genetic Algorithm for optimal task scheduling
/// Uses evolutionary computation to find the best task arrangement
class GeneticScheduleOptimizer {
  final List<EnhancedTask> tasks;
  final Map<String, dynamic> constraints;
  final Map<String, dynamic> workPatterns;
  final Random _random = Random();

  GeneticScheduleOptimizer({
    required this.tasks,
    required this.constraints,
    required this.workPatterns,
  });

  /// Optimize schedule using genetic algorithm
  Future<ScheduleOptimizationResult> optimize({
    int generations = 100,
    int populationSize = 50,
    double mutationRate = 0.1,
    double crossoverRate = 0.8,
  }) async {
    // Initialize population
    List<Schedule> population = _initializePopulation(populationSize);
    Schedule bestSchedule = population.first;
    double bestFitness = _calculateFitness(bestSchedule);

    for (int generation = 0; generation < generations; generation++) {
      // Evaluate fitness for all schedules
      final fitnessScores = population.map(_calculateFitness).toList();

      // Find best in this generation
      final maxFitness = fitnessScores.reduce(max);
      if (maxFitness > bestFitness) {
        bestFitness = maxFitness;
        final bestIndex = fitnessScores.indexOf(maxFitness);
        bestSchedule = population[bestIndex];
      }

      // Create new generation
      final newPopulation = <Schedule>[];

      // Elitism - keep best individuals
      final eliteCount = (populationSize * 0.1).round();
      final sortedIndices = List.generate(population.length, (i) => i)
        ..sort((a, b) => fitnessScores[b].compareTo(fitnessScores[a]));

      for (int i = 0; i < eliteCount; i++) {
        newPopulation.add(population[sortedIndices[i]]);
      }

      // Generate rest through crossover and mutation
      while (newPopulation.length < populationSize) {
        final parent1 = _tournamentSelection(population, fitnessScores);
        final parent2 = _tournamentSelection(population, fitnessScores);

        Schedule offspring;
        if (_random.nextDouble() < crossoverRate) {
          offspring = _crossover(parent1, parent2);
        } else {
          offspring = _random.nextBool() ? parent1 : parent2;
        }

        if (_random.nextDouble() < mutationRate) {
          offspring = _mutate(offspring);
        }

        newPopulation.add(offspring);
      }

      population = newPopulation;
    }

    return ScheduleOptimizationResult(
      bestSchedule: _convertToScheduledTasks(bestSchedule),
      fitnessScore: bestFitness / 100.0, // Normalize to 0-1 range
      alternatives: _generateAlternatives(population),
      tips: _generateOptimizationTips(bestSchedule),
      risks: _identifyScheduleRisks(bestSchedule),
    );
  }

  /// Initialize random population of schedules
  List<Schedule> _initializePopulation(int populationSize) {
    final population = <Schedule>[];

    for (int i = 0; i < populationSize; i++) {
      final schedule = Schedule(taskOrder: List.from(tasks)..shuffle(_random));
      population.add(schedule);
    }

    return population;
  }

  /// Calculate fitness score for a schedule
  double _calculateFitness(Schedule schedule) {
    double fitness = 0.0;

    // Factor 1: Task completion feasibility (40%)
    fitness += _evaluateCompletionFeasibility(schedule) * 40;

    // Factor 2: Priority optimization (30%)
    fitness += _evaluatePriorityOptimization(schedule) * 30;

    // Factor 3: Work pattern alignment (20%)
    fitness += _evaluateWorkPatternAlignment(schedule) * 20;

    // Factor 4: Deadline adherence (10%)
    fitness += _evaluateDeadlineAdherence(schedule) * 10;

    return fitness.clamp(0.0, 100.0);
  }

  double _evaluateCompletionFeasibility(Schedule schedule) {
    final workHoursPerDay = constraints['workHoursPerDay'] as double? ?? 8.0;
    final totalWorkMinutes = workHoursPerDay * 60;
    double currentDayMinutes = 0.0;
    int completableTasks = 0;

    for (final task in schedule.taskOrder) {
      if (currentDayMinutes + task.estimatedMinutes <= totalWorkMinutes) {
        completableTasks++;
        currentDayMinutes += task.estimatedMinutes;
      } else {
        currentDayMinutes = task.estimatedMinutes.toDouble();
        if (currentDayMinutes <= totalWorkMinutes) {
          completableTasks++;
        }
      }
    }

    return completableTasks / schedule.taskOrder.length;
  }

  double _evaluatePriorityOptimization(Schedule schedule) {
    double score = 0.0;
    double totalWeight = 0.0;

    for (int i = 0; i < schedule.taskOrder.length; i++) {
      final task = schedule.taskOrder[i];
      final priorityWeight = _getPriorityWeight(task.priority);
      final positionPenalty = i / schedule.taskOrder.length;

      score += priorityWeight * (1.0 - positionPenalty);
      totalWeight += priorityWeight;
    }

    return totalWeight > 0 ? score / totalWeight : 0.0;
  }

  double _evaluateWorkPatternAlignment(Schedule schedule) {
    final peakHours =
        workPatterns['peakHours'] as List<int>? ?? [9, 10, 11, 14, 15];
    double alignment = 0.0;

    int currentHour = 9; // Start at 9 AM
    for (final task in schedule.taskOrder) {
      if (peakHours.contains(currentHour)) {
        alignment += _getPriorityWeight(task.priority);
      }

      currentHour += (task.estimatedMinutes / 60).ceil();
      if (currentHour >= 18) currentHour = 9; // Next day
    }

    return alignment / schedule.taskOrder.length;
  }

  double _evaluateDeadlineAdherence(Schedule schedule) {
    double adherenceScore = 0.0;
    int tasksWithDeadlines = 0;

    DateTime currentTime = DateTime.now();
    for (final task in schedule.taskOrder) {
      if (task.dueDate != null) {
        tasksWithDeadlines++;
        final timeUntilDeadline = task.dueDate!.difference(currentTime).inHours;

        if (timeUntilDeadline > 0) {
          adherenceScore += 1.0;
        } else {
          adherenceScore +=
              max(0.0, 1.0 + (timeUntilDeadline / 24)); // Penalty for overdue
        }
      }

      currentTime = currentTime.add(Duration(minutes: task.estimatedMinutes));
    }

    return tasksWithDeadlines > 0 ? adherenceScore / tasksWithDeadlines : 1.0;
  }

  double _getPriorityWeight(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.critical:
        return 4.0;
      case TaskPriority.high:
        return 3.0;
      case TaskPriority.medium:
        return 2.0;
      case TaskPriority.low:
        return 1.0;
    }
  }

  /// Tournament selection for parent selection
  Schedule _tournamentSelection(
      List<Schedule> population, List<double> fitnessScores) {
    const tournamentSize = 3;
    Schedule best = population[_random.nextInt(population.length)];
    double bestFitness = fitnessScores[population.indexOf(best)];

    for (int i = 1; i < tournamentSize; i++) {
      final candidate = population[_random.nextInt(population.length)];
      final candidateFitness = fitnessScores[population.indexOf(candidate)];

      if (candidateFitness > bestFitness) {
        best = candidate;
        bestFitness = candidateFitness;
      }
    }

    return best;
  }

  /// Crossover operation between two parent schedules
  Schedule _crossover(Schedule parent1, Schedule parent2) {
    final length = parent1.taskOrder.length;
    final crossoverPoint = _random.nextInt(length);

    final childOrder = <EnhancedTask>[];
    final used = <String>{};

    // Take first part from parent1
    for (int i = 0; i < crossoverPoint; i++) {
      final task = parent1.taskOrder[i];
      childOrder.add(task);
      used.add(task.id);
    }

    // Fill remaining with parent2's order
    for (final task in parent2.taskOrder) {
      if (!used.contains(task.id)) {
        childOrder.add(task);
      }
    }

    return Schedule(taskOrder: childOrder);
  }

  /// Mutation operation on a schedule
  Schedule _mutate(Schedule schedule) {
    final newOrder = List<EnhancedTask>.from(schedule.taskOrder);

    // Swap two random tasks
    if (newOrder.length >= 2) {
      final index1 = _random.nextInt(newOrder.length);
      final index2 = _random.nextInt(newOrder.length);

      final temp = newOrder[index1];
      newOrder[index1] = newOrder[index2];
      newOrder[index2] = temp;
    }

    return Schedule(taskOrder: newOrder);
  }

  List<ScheduledTask> _convertToScheduledTasks(Schedule schedule) {
    final scheduledTasks = <ScheduledTask>[];
    DateTime currentTime = DateTime.now();

    for (final task in schedule.taskOrder) {
      final startTime = currentTime;
      final endTime = startTime.add(Duration(minutes: task.estimatedMinutes));

      scheduledTasks.add(ScheduledTask(
        taskId: task.id,
        startTime: startTime,
        endTime: endTime,
        confidence: 0.8,
      ));

      currentTime = endTime.add(const Duration(minutes: 5)); // 5-minute break
    }

    return scheduledTasks;
  }

  List<ScheduledTask> _generateAlternatives(List<Schedule> population) {
    // Return second-best schedule as alternative
    if (population.length < 2) return [];

    final fitnessScores = population.map(_calculateFitness).toList();
    final sortedIndices = List.generate(population.length, (i) => i)
      ..sort((a, b) => fitnessScores[b].compareTo(fitnessScores[a]));

    return _convertToScheduledTasks(population[sortedIndices[1]]);
  }

  List<String> _generateOptimizationTips(Schedule schedule) {
    final tips = <String>[];

    // Analyze high-priority task distribution
    final highPriorityTasks = schedule.taskOrder
        .where((t) =>
            t.priority == TaskPriority.high ||
            t.priority == TaskPriority.critical)
        .length;

    if (highPriorityTasks > schedule.taskOrder.length * 0.3) {
      tips.add(
          'Consider breaking down high-priority tasks into smaller chunks');
    }

    // Check for long consecutive work periods
    int consecutiveMinutes = 0;
    for (final task in schedule.taskOrder) {
      consecutiveMinutes += task.estimatedMinutes;
      if (consecutiveMinutes > 120) {
        tips.add('Schedule longer breaks after intensive work periods');
        break;
      }
    }

    // Suggest peak hours utilization
    tips.add(
        'Schedule your most challenging tasks during your peak performance hours');

    return tips;
  }

  List<String> _identifyScheduleRisks(Schedule schedule) {
    final risks = <String>[];

    // Check for overloaded days
    final totalMinutes = schedule.taskOrder
        .fold<int>(0, (sum, task) => sum + task.estimatedMinutes);
    final workDays = (totalMinutes / (8 * 60)).ceil();

    if (workDays > 5) {
      risks.add(
          'Schedule spans multiple weeks - consider prioritizing critical tasks');
    }

    // Check for deadline conflicts
    final tasksWithDeadlines =
        schedule.taskOrder.where((t) => t.dueDate != null);
    for (final task in tasksWithDeadlines) {
      if (task.dueDate!.isBefore(DateTime.now().add(const Duration(days: 1)))) {
        risks.add('Task "${task.title}" has a tight deadline');
      }
    }

    return risks;
  }
}

/// Represents a schedule solution
class Schedule {
  final List<EnhancedTask> taskOrder;

  Schedule({required this.taskOrder});
}

/// Results from genetic algorithm optimization
class ScheduleOptimizationResult {
  final List<ScheduledTask> bestSchedule;
  final double fitnessScore;
  final List<ScheduledTask> alternatives;
  final List<String> tips;
  final List<String> risks;

  ScheduleOptimizationResult({
    required this.bestSchedule,
    required this.fitnessScore,
    required this.alternatives,
    required this.tips,
    required this.risks,
  });
}
