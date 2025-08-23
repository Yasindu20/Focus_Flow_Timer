/**
 * Task Intelligence Service
 * Handles AI-powered task processing and enhancement
 */

import { aiService } from './aiService';

interface TaskInput {
  title: string;
  description: string;
  category: string;
  priority: string;
  userContext?: any;
}

interface TaskIntelligenceResult {
  estimatedDuration: number;
  complexityScore: number;
  tags: string[];
  suggestedTimeSlots: string[];
  optimizationTips: string[];
  relatedTasks: string[];
  urgency: string;
  cognitiveLoad: number;
  prerequisites: string[];
  confidence: number;
  processingMetadata: {
    processedAt: string;
    version: string;
    methods: string[];
  };
}

export class TaskIntelligenceService {

  /**
   * Process a task with comprehensive AI analysis
   */
  async processTask(taskInput: TaskInput): Promise<TaskIntelligenceResult> {
    console.log(`Processing task intelligence for: ${taskInput.title}`);
    
    try {
      // Start processing timestamp
      const startTime = Date.now();

      // Use AI service to process the task
      const aiResult = await aiService.processTask(taskInput);

      // Calculate confidence based on available data
      const confidence = this.calculateConfidence(taskInput, aiResult);

      // Processing metadata
      const processingMetadata = {
        processedAt: new Date().toISOString(),
        version: '1.0.0',
        methods: ['nlp', 'duration_estimation', 'complexity_analysis', 'recommendations'],
        processingTimeMs: Date.now() - startTime,
      };

      const result: TaskIntelligenceResult = {
        estimatedDuration: aiResult.estimatedDuration,
        complexityScore: aiResult.complexityScore,
        tags: aiResult.tags,
        suggestedTimeSlots: aiResult.suggestedTimeSlots,
        optimizationTips: aiResult.optimizationTips,
        relatedTasks: aiResult.relatedTasks,
        urgency: aiResult.urgency,
        cognitiveLoad: aiResult.cognitiveLoad,
        prerequisites: aiResult.prerequisites,
        confidence,
        processingMetadata,
      };

      console.log(`Task intelligence processing completed in ${processingMetadata.processingTimeMs}ms`);
      return result;

    } catch (error) {
      console.error('Task intelligence processing error:', error);
      
      // Return fallback result
      return this.getFallbackResult(taskInput);
    }
  }

  /**
   * Calculate confidence score based on available data and processing results
   */
  private calculateConfidence(taskInput: TaskInput, aiResult: any): number {
    let confidence = 0.5; // Base confidence

    // Title quality (longer, more descriptive titles get higher confidence)
    if (taskInput.title.length > 10) confidence += 0.1;
    if (taskInput.title.length > 25) confidence += 0.1;

    // Description quality
    if (taskInput.description && taskInput.description.length > 20) confidence += 0.15;
    if (taskInput.description && taskInput.description.length > 100) confidence += 0.15;

    // User context availability
    if (taskInput.userContext?.uid) confidence += 0.1;

    // AI processing success indicators
    if (aiResult.tags && aiResult.tags.length > 0) confidence += 0.1;
    if (aiResult.optimizationTips && aiResult.optimizationTips.length > 0) confidence += 0.1;
    if (aiResult.suggestedTimeSlots && aiResult.suggestedTimeSlots.length > 0) confidence += 0.05;

    // Category specificity
    if (taskInput.category !== 'general') confidence += 0.05;

    // Priority specificity
    if (taskInput.priority !== 'medium') confidence += 0.05;

    return Math.min(confidence, 0.95); // Cap at 95%
  }

  /**
   * Get fallback result when AI processing fails
   */
  private getFallbackResult(taskInput: TaskInput): TaskIntelligenceResult {
    const categoryDefaults: { [key: string]: Partial<TaskIntelligenceResult> } = {
      'planning': {
        estimatedDuration: 30,
        complexityScore: 0.4,
        suggestedTimeSlots: ['morning'],
        optimizationTips: ['Create clear objectives', 'Break into phases'],
        cognitiveLoad: 0.6,
      },
      'coding': {
        estimatedDuration: 60,
        complexityScore: 0.7,
        suggestedTimeSlots: ['morning', 'afternoon'],
        optimizationTips: ['Use focus blocks', 'Test incrementally'],
        cognitiveLoad: 0.8,
      },
      'testing': {
        estimatedDuration: 45,
        complexityScore: 0.5,
        suggestedTimeSlots: ['afternoon'],
        optimizationTips: ['Prepare test cases', 'Document findings'],
        cognitiveLoad: 0.6,
      },
      'documentation': {
        estimatedDuration: 35,
        complexityScore: 0.3,
        suggestedTimeSlots: ['afternoon', 'evening'],
        optimizationTips: ['Outline first', 'Use templates'],
        cognitiveLoad: 0.4,
      },
      'meeting': {
        estimatedDuration: 30,
        complexityScore: 0.2,
        suggestedTimeSlots: ['morning', 'afternoon'],
        optimizationTips: ['Prepare agenda', 'Take notes'],
        cognitiveLoad: 0.3,
      },
      'research': {
        estimatedDuration: 90,
        complexityScore: 0.6,
        suggestedTimeSlots: ['morning'],
        optimizationTips: ['Define scope', 'Use multiple sources'],
        cognitiveLoad: 0.7,
      },
      'design': {
        estimatedDuration: 75,
        complexityScore: 0.8,
        suggestedTimeSlots: ['morning', 'afternoon'],
        optimizationTips: ['Start with wireframes', 'Iterate frequently'],
        cognitiveLoad: 0.8,
      },
      'review': {
        estimatedDuration: 20,
        complexityScore: 0.3,
        suggestedTimeSlots: ['afternoon', 'evening'],
        optimizationTips: ['Use checklists', 'Focus on key areas'],
        cognitiveLoad: 0.4,
      },
    };

    const defaults = categoryDefaults[taskInput.category] || categoryDefaults['planning'];
    
    // Map priority to urgency
    const priorityUrgencyMap: { [key: string]: string } = {
      'low': 'low',
      'medium': 'medium',
      'high': 'high',
      'critical': 'critical',
    };

    return {
      estimatedDuration: defaults.estimatedDuration || 25,
      complexityScore: defaults.complexityScore || 0.5,
      tags: [taskInput.category, taskInput.priority],
      suggestedTimeSlots: defaults.suggestedTimeSlots || ['morning'],
      optimizationTips: defaults.optimizationTips || ['Break into smaller chunks'],
      relatedTasks: [],
      urgency: priorityUrgencyMap[taskInput.priority] || 'medium',
      cognitiveLoad: defaults.cognitiveLoad || 0.5,
      prerequisites: [],
      confidence: 0.3, // Lower confidence for fallback
      processingMetadata: {
        processedAt: new Date().toISOString(),
        version: '1.0.0',
        methods: ['fallback'],
      },
    };
  }

  /**
   * Batch process multiple tasks
   */
  async processTasks(tasks: TaskInput[]): Promise<{ [taskId: string]: TaskIntelligenceResult }> {
    const results: { [taskId: string]: TaskIntelligenceResult } = {};
    
    // Process tasks in parallel batches to avoid overwhelming the AI service
    const batchSize = 5;
    const batches = [];
    
    for (let i = 0; i < tasks.length; i += batchSize) {
      batches.push(tasks.slice(i, i + batchSize));
    }

    for (const batch of batches) {
      const batchPromises = batch.map(async (task, index) => {
        try {
          const result = await this.processTask(task);
          return { index, result };
        } catch (error) {
          console.error(`Error processing task ${index}:`, error);
          return { index, result: this.getFallbackResult(task) };
        }
      });

      const batchResults = await Promise.all(batchPromises);
      
      // Collect results
      batchResults.forEach(({ index, result }) => {
        const taskIndex = batches.indexOf(batch) * batchSize + index;
        results[`task_${taskIndex}`] = result;
      });

      // Small delay between batches to respect rate limits
      if (batches.indexOf(batch) < batches.length - 1) {
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
    }

    return results;
  }

  /**
   * Update task intelligence based on completion feedback
   */
  async updateTaskIntelligence(
    taskId: string,
    actualDuration: number,
    userFeedback: {
      accuracyRating: number; // 1-5
      difficultyRating: number; // 1-5
      timeSlotEffectiveness: number; // 1-5
      tips_helpful: boolean;
    }
  ): Promise<void> {
    try {
      // This would be used to improve future predictions
      // Store feedback for machine learning model training
      const feedbackData = {
        taskId,
        actualDuration,
        userFeedback,
        timestamp: new Date().toISOString(),
      };

      console.log('Task intelligence feedback recorded:', feedbackData);
      
      // In a production system, this would:
      // 1. Store feedback in a training dataset
      // 2. Trigger model retraining if enough feedback is collected
      // 3. Update user-specific prediction models
      
    } catch (error) {
      console.error('Error updating task intelligence:', error);
    }
  }

  /**
   * Get intelligence summary for a user's tasks
   */
  async getIntelligenceSummary(userId: string): Promise<{
    totalTasksProcessed: number;
    averageAccuracy: number;
    topCategories: string[];
    improvementSuggestions: string[];
  }> {
    try {
      // This would analyze the user's historical task intelligence data
      // and provide insights about prediction accuracy and suggestions

      return {
        totalTasksProcessed: 0,
        averageAccuracy: 0,
        topCategories: [],
        improvementSuggestions: [
          'Provide more detailed task descriptions for better estimates',
          'Use specific categories to improve accuracy',
          'Rate completed tasks to help improve predictions',
        ],
      };

    } catch (error) {
      console.error('Error generating intelligence summary:', error);
      throw error;
    }
  }
}

export const taskIntelligenceService = new TaskIntelligenceService();