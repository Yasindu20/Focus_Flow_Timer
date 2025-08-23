/**
 * AI Service for Focus Flow Timer
 * Handles machine learning, natural language processing, and task intelligence
 */

import * as admin from 'firebase-admin';
import { Language } from '@google-cloud/language';
import OpenAI from 'openai';

const db = admin.firestore();
const language = new Language();

// Initialize OpenAI (use environment variable for API key)
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY || '',
});

interface TaskContext {
  title: string;
  description: string;
  category: string;
  priority: string;
  userContext?: any;
}

interface TaskAIData {
  estimatedDuration: number; // in minutes
  complexityScore: number; // 0-1
  tags: string[];
  suggestedTimeSlots: string[];
  optimizationTips: string[];
  relatedTasks: string[];
  urgency: 'low' | 'medium' | 'high' | 'critical';
  cognitiveLoad: number; // 0-1
  prerequisites: string[];
}

export class AIService {
  
  /**
   * Process a task with AI enhancement
   */
  async processTask(taskContext: TaskContext): Promise<TaskAIData> {
    try {
      console.log(`AI processing task: ${taskContext.title}`);

      // Perform parallel AI analysis
      const [
        nlpAnalysis,
        durationEstimate,
        complexityAnalysis,
        recommendations
      ] = await Promise.all([
        this.analyzeTaskWithNLP(taskContext),
        this.estimateTaskDuration(taskContext),
        this.analyzeTaskComplexity(taskContext),
        this.generateTaskRecommendations(taskContext)
      ]);

      // Combine results
      const aiData: TaskAIData = {
        estimatedDuration: durationEstimate.minutes,
        complexityScore: complexityAnalysis.score,
        tags: [...nlpAnalysis.entities, ...nlpAnalysis.keywords],
        suggestedTimeSlots: recommendations.timeSlots,
        optimizationTips: recommendations.tips,
        relatedTasks: recommendations.relatedTasks,
        urgency: this.calculateUrgency(taskContext, complexityAnalysis),
        cognitiveLoad: complexityAnalysis.cognitiveLoad,
        prerequisites: recommendations.prerequisites,
      };

      console.log(`AI processing completed for: ${taskContext.title}`);
      return aiData;

    } catch (error) {
      console.error('AI task processing error:', error);
      
      // Return fallback data
      return this.getFallbackAIData(taskContext);
    }
  }

  /**
   * Analyze task using Google Cloud Natural Language API
   */
  private async analyzeTaskWithNLP(taskContext: TaskContext) {
    try {
      const text = `${taskContext.title} ${taskContext.description}`.trim();
      
      if (!text) {
        return { entities: [], keywords: [], sentiment: 0.5 };
      }

      const [entitiesResult, sentimentResult] = await Promise.all([
        language.analyzeEntities({ document: { content: text, type: 'PLAIN_TEXT' } }),
        language.analyzeSentiment({ document: { content: text, type: 'PLAIN_TEXT' } }),
      ]);

      const entities = entitiesResult[0].entities?.map(entity => entity.name) || [];
      const sentiment = sentimentResult[0].documentSentiment?.score || 0;
      
      // Extract keywords using OpenAI
      const keywords = await this.extractKeywords(text);

      return {
        entities: entities.slice(0, 5), // Top 5 entities
        keywords: keywords.slice(0, 10), // Top 10 keywords
        sentiment: (sentiment + 1) / 2, // Normalize to 0-1
      };

    } catch (error) {
      console.error('NLP analysis error:', error);
      return { entities: [], keywords: [], sentiment: 0.5 };
    }
  }

  /**
   * Extract keywords using OpenAI
   */
  private async extractKeywords(text: string): Promise<string[]> {
    try {
      const response = await openai.chat.completions.create({
        model: 'gpt-3.5-turbo',
        messages: [
          {
            role: 'system',
            content: 'Extract 5-10 relevant keywords from the given task text. Return only keywords separated by commas, no explanations.'
          },
          {
            role: 'user',
            content: text
          }
        ],
        max_tokens: 100,
        temperature: 0.3,
      });

      const keywords = response.choices[0]?.message?.content
        ?.split(',')
        .map(k => k.trim().toLowerCase())
        .filter(k => k.length > 2) || [];

      return keywords;

    } catch (error) {
      console.error('Keyword extraction error:', error);
      return [];
    }
  }

  /**
   * Estimate task duration using multiple methods
   */
  private async estimateTaskDuration(taskContext: TaskContext): Promise<{ minutes: number; confidence: number }> {
    try {
      // Method 1: Historical data-based estimation
      const historicalEstimate = await this.getHistoricalDurationEstimate(taskContext);
      
      // Method 2: AI-based estimation using OpenAI
      const aiEstimate = await this.getAIDurationEstimate(taskContext);
      
      // Method 3: Category-based estimation
      const categoryEstimate = this.getCategoryBasedEstimate(taskContext.category);
      
      // Method 4: Complexity-based estimation
      const complexityEstimate = await this.getComplexityBasedEstimate(taskContext);

      // Ensemble method: weighted average
      const estimates = [
        { value: historicalEstimate.minutes, weight: historicalEstimate.confidence },
        { value: aiEstimate.minutes, weight: aiEstimate.confidence },
        { value: categoryEstimate.minutes, weight: categoryEstimate.confidence },
        { value: complexityEstimate.minutes, weight: complexityEstimate.confidence },
      ].filter(est => est.value > 0);

      if (estimates.length === 0) {
        return { minutes: 25, confidence: 0.3 }; // Default Pomodoro
      }

      const totalWeight = estimates.reduce((sum, est) => sum + est.weight, 0);
      const weightedAverage = estimates.reduce((sum, est) => sum + est.value * est.weight, 0) / totalWeight;
      const avgConfidence = totalWeight / estimates.length;

      return {
        minutes: Math.round(weightedAverage),
        confidence: Math.min(avgConfidence, 0.95)
      };

    } catch (error) {
      console.error('Duration estimation error:', error);
      return { minutes: 25, confidence: 0.3 };
    }
  }

  /**
   * Get historical duration estimate based on similar tasks
   */
  private async getHistoricalDurationEstimate(taskContext: TaskContext): Promise<{ minutes: number; confidence: number }> {
    try {
      if (!taskContext.userContext?.uid) {
        return { minutes: 0, confidence: 0 };
      }

      // Find similar completed tasks
      const tasksSnapshot = await db
        .collection('users')
        .doc(taskContext.userContext.uid)
        .collection('tasks')
        .where('isCompleted', '==', true)
        .where('category', '==', taskContext.category)
        .limit(20)
        .get();

      if (tasksSnapshot.empty) {
        return { minutes: 0, confidence: 0 };
      }

      const durations: number[] = [];
      tasksSnapshot.forEach(doc => {
        const task = doc.data();
        if (task.actualDuration) {
          durations.push(task.actualDuration);
        }
      });

      if (durations.length === 0) {
        return { minutes: 0, confidence: 0 };
      }

      const avgDuration = durations.reduce((sum, d) => sum + d, 0) / durations.length;
      const confidence = Math.min(durations.length / 10, 0.8); // Higher confidence with more data

      return {
        minutes: Math.round(avgDuration / 60000), // Convert to minutes
        confidence
      };

    } catch (error) {
      console.error('Historical estimation error:', error);
      return { minutes: 0, confidence: 0 };
    }
  }

  /**
   * Get AI-based duration estimate using OpenAI
   */
  private async getAIDurationEstimate(taskContext: TaskContext): Promise<{ minutes: number; confidence: number }> {
    try {
      const response = await openai.chat.completions.create({
        model: 'gpt-3.5-turbo',
        messages: [
          {
            role: 'system',
            content: `You are an expert productivity consultant. Estimate how long a task will take in minutes based on the title, description, category, and priority. 

Consider:
- Task complexity and scope
- Category-specific time patterns
- Priority level impact
- Typical cognitive load

Respond with only a number (minutes) and confidence (0-1) in format: "minutes,confidence"`
          },
          {
            role: 'user',
            content: `Task: ${taskContext.title}
Description: ${taskContext.description}
Category: ${taskContext.category}
Priority: ${taskContext.priority}`
          }
        ],
        max_tokens: 50,
        temperature: 0.2,
      });

      const result = response.choices[0]?.message?.content?.trim();
      const [minutesStr, confidenceStr] = result?.split(',') || [];
      
      const minutes = parseInt(minutesStr) || 25;
      const confidence = parseFloat(confidenceStr) || 0.5;

      return {
        minutes: Math.max(5, Math.min(240, minutes)), // Clamp between 5 and 240 minutes
        confidence: Math.max(0.1, Math.min(0.9, confidence))
      };

    } catch (error) {
      console.error('AI estimation error:', error);
      return { minutes: 25, confidence: 0.4 };
    }
  }

  /**
   * Get category-based duration estimate
   */
  private getCategoryBasedEstimate(category: string): { minutes: number; confidence: number } {
    const categoryEstimates: { [key: string]: { minutes: number; confidence: number } } = {
      'planning': { minutes: 30, confidence: 0.6 },
      'coding': { minutes: 60, confidence: 0.7 },
      'testing': { minutes: 45, confidence: 0.6 },
      'documentation': { minutes: 35, confidence: 0.5 },
      'meeting': { minutes: 30, confidence: 0.8 },
      'research': { minutes: 90, confidence: 0.5 },
      'design': { minutes: 75, confidence: 0.6 },
      'review': { minutes: 20, confidence: 0.7 },
      'general': { minutes: 25, confidence: 0.4 }
    };

    return categoryEstimates[category.toLowerCase()] || categoryEstimates['general'];
  }

  /**
   * Get complexity-based duration estimate
   */
  private async getComplexityBasedEstimate(taskContext: TaskContext): Promise<{ minutes: number; confidence: number }> {
    try {
      // Analyze task complexity based on various factors
      const titleLength = taskContext.title.length;
      const descriptionLength = taskContext.description.length;
      const wordCount = (taskContext.title + ' ' + taskContext.description).split(' ').length;
      
      // Technical keywords that indicate complexity
      const complexKeywords = [
        'integrate', 'implement', 'develop', 'design', 'architecture', 'algorithm',
        'optimize', 'performance', 'security', 'database', 'api', 'framework',
        'analysis', 'research', 'investigate', 'troubleshoot', 'debug'
      ];

      const text = (taskContext.title + ' ' + taskContext.description).toLowerCase();
      const complexityIndicators = complexKeywords.filter(keyword => text.includes(keyword)).length;
      
      // Calculate complexity score (0-1)
      let complexityScore = 0;
      complexityScore += Math.min(titleLength / 100, 0.3); // Title length factor
      complexityScore += Math.min(descriptionLength / 500, 0.4); // Description length factor
      complexityScore += Math.min(complexityIndicators / 5, 0.3); // Technical complexity factor

      // Map complexity to duration
      const baseDuration = 25; // Base Pomodoro
      const complexityMultiplier = 1 + (complexityScore * 3); // 1x to 4x multiplier
      const estimatedMinutes = Math.round(baseDuration * complexityMultiplier);

      return {
        minutes: Math.max(15, Math.min(180, estimatedMinutes)),
        confidence: 0.6
      };

    } catch (error) {
      console.error('Complexity estimation error:', error);
      return { minutes: 25, confidence: 0.3 };
    }
  }

  /**
   * Analyze task complexity
   */
  private async analyzeTaskComplexity(taskContext: TaskContext): Promise<{
    score: number;
    cognitiveLoad: number;
    factors: string[];
  }> {
    try {
      const text = (taskContext.title + ' ' + taskContext.description).toLowerCase();
      
      // Complexity factors
      const factors = [];
      let complexityScore = 0;
      let cognitiveLoad = 0.3; // Base cognitive load

      // Technical complexity indicators
      const technicalKeywords = [
        'algorithm', 'optimization', 'architecture', 'integration', 'security',
        'performance', 'scalability', 'database', 'api', 'framework'
      ];
      
      const foundTechnical = technicalKeywords.filter(keyword => text.includes(keyword));
      if (foundTechnical.length > 0) {
        complexityScore += 0.3;
        cognitiveLoad += 0.2;
        factors.push('Technical complexity');
      }

      // Problem-solving indicators
      const problemKeywords = [
        'debug', 'troubleshoot', 'investigate', 'analyze', 'research',
        'solve', 'fix', 'resolve', 'diagnose'
      ];
      
      const foundProblem = problemKeywords.filter(keyword => text.includes(keyword));
      if (foundProblem.length > 0) {
        complexityScore += 0.25;
        cognitiveLoad += 0.3;
        factors.push('Problem-solving required');
      }

      // Creative work indicators
      const creativeKeywords = [
        'design', 'create', 'develop', 'innovate', 'brainstorm',
        'concept', 'prototype', 'ideate'
      ];
      
      const foundCreative = creativeKeywords.filter(keyword => text.includes(keyword));
      if (foundCreative.length > 0) {
        complexityScore += 0.2;
        cognitiveLoad += 0.2;
        factors.push('Creative work');
      }

      // Documentation and communication
      const docKeywords = [
        'document', 'write', 'report', 'present', 'communicate',
        'explain', 'teach', 'review'
      ];
      
      const foundDoc = docKeywords.filter(keyword => text.includes(keyword));
      if (foundDoc.length > 0) {
        complexityScore += 0.15;
        factors.push('Documentation/Communication');
      }

      // Multi-step processes
      const processKeywords = [
        'implement', 'deploy', 'setup', 'configure', 'install',
        'migrate', 'upgrade', 'refactor'
      ];
      
      const foundProcess = processKeywords.filter(keyword => text.includes(keyword));
      if (foundProcess.length > 0) {
        complexityScore += 0.2;
        factors.push('Multi-step process');
      }

      // Priority impact on complexity
      if (taskContext.priority === 'critical' || taskContext.priority === 'high') {
        complexityScore += 0.1;
        cognitiveLoad += 0.1;
        factors.push('High priority pressure');
      }

      // Text length impact
      const wordCount = text.split(' ').length;
      if (wordCount > 50) {
        complexityScore += 0.1;
        factors.push('Detailed requirements');
      }

      return {
        score: Math.min(complexityScore, 1.0),
        cognitiveLoad: Math.min(cognitiveLoad, 1.0),
        factors
      };

    } catch (error) {
      console.error('Complexity analysis error:', error);
      return {
        score: 0.5,
        cognitiveLoad: 0.5,
        factors: ['Unable to analyze']
      };
    }
  }

  /**
   * Generate task recommendations
   */
  private async generateTaskRecommendations(taskContext: TaskContext): Promise<{
    timeSlots: string[];
    tips: string[];
    relatedTasks: string[];
    prerequisites: string[];
  }> {
    try {
      const response = await openai.chat.completions.create({
        model: 'gpt-3.5-turbo',
        messages: [
          {
            role: 'system',
            content: `You are a productivity expert. Analyze the task and provide recommendations in JSON format:
{
  "timeSlots": ["morning", "afternoon", "evening"],
  "tips": ["tip1", "tip2", "tip3"],
  "prerequisites": ["prereq1", "prereq2"],
  "relatedTasks": ["related1", "related2"]
}

Consider:
- Optimal times for this type of work
- Productivity tips specific to the task
- What needs to be done first
- Similar or related tasks that could be grouped`
          },
          {
            role: 'user',
            content: `Task: ${taskContext.title}
Description: ${taskContext.description}
Category: ${taskContext.category}
Priority: ${taskContext.priority}`
          }
        ],
        max_tokens: 400,
        temperature: 0.4,
      });

      const result = response.choices[0]?.message?.content;
      if (!result) {
        return this.getFallbackRecommendations();
      }

      try {
        const parsed = JSON.parse(result);
        return {
          timeSlots: parsed.timeSlots || [],
          tips: parsed.tips || [],
          relatedTasks: parsed.relatedTasks || [],
          prerequisites: parsed.prerequisites || []
        };
      } catch {
        return this.getFallbackRecommendations();
      }

    } catch (error) {
      console.error('Recommendations error:', error);
      return this.getFallbackRecommendations();
    }
  }

  /**
   * Calculate urgency based on various factors
   */
  private calculateUrgency(taskContext: TaskContext, complexityAnalysis: any): 'low' | 'medium' | 'high' | 'critical' {
    let urgencyScore = 0;

    // Priority impact
    const priorityMap = { low: 0, medium: 1, high: 2, critical: 3 };
    urgencyScore += (priorityMap[taskContext.priority as keyof typeof priorityMap] || 1) * 0.4;

    // Complexity impact (higher complexity = higher urgency to start early)
    urgencyScore += complexityAnalysis.score * 0.3;

    // Keywords that indicate urgency
    const urgentKeywords = [
      'urgent', 'asap', 'immediately', 'critical', 'emergency',
      'deadline', 'due', 'blocking', 'urgent'
    ];
    
    const text = (taskContext.title + ' ' + taskContext.description).toLowerCase();
    const urgentMatches = urgentKeywords.filter(keyword => text.includes(keyword)).length;
    urgencyScore += Math.min(urgentMatches * 0.2, 0.3);

    // Map score to urgency level
    if (urgencyScore >= 2.5) return 'critical';
    if (urgencyScore >= 2.0) return 'high';
    if (urgencyScore >= 1.0) return 'medium';
    return 'low';
  }

  /**
   * Generate task recommendations for a user
   */
  async generateTaskRecommendations(tasks: any[], userAnalytics: any): Promise<any[]> {
    try {
      if (!tasks || tasks.length === 0) {
        return [];
      }

      // Sort tasks by multiple factors
      const scoredTasks = tasks.map(task => {
        let score = 0;

        // Priority weight
        const priorityWeights = { low: 1, medium: 2, high: 3, critical: 4 };
        score += (priorityWeights[task.priority as keyof typeof priorityWeights] || 2) * 0.3;

        // Complexity weight (prefer moderate complexity for recommendations)
        const complexityScore = task.aiData?.complexityScore || 0.5;
        score += (1 - Math.abs(complexityScore - 0.6)) * 0.2; // Optimal complexity around 0.6

        // Urgency weight
        const urgencyWeights = { low: 1, medium: 2, high: 3, critical: 4 };
        score += (urgencyWeights[task.aiData?.urgency as keyof typeof urgencyWeights] || 2) * 0.25;

        // Recency weight (newer tasks get slight preference)
        const ageInDays = (Date.now() - new Date(task.createdAt).getTime()) / (1000 * 60 * 60 * 24);
        score += Math.max(0, 1 - ageInDays / 7) * 0.1; // Decay over a week

        // User pattern alignment (if available)
        if (userAnalytics?.preferredCategories?.[task.category]) {
          score += 0.15;
        }

        return { ...task, recommendationScore: score };
      });

      // Sort by score and return top recommendations
      return scoredTasks
        .sort((a, b) => b.recommendationScore - a.recommendationScore)
        .slice(0, 5);

    } catch (error) {
      console.error('Task recommendations error:', error);
      return tasks.slice(0, 5); // Return first 5 as fallback
    }
  }

  /**
   * Fallback AI data when processing fails
   */
  private getFallbackAIData(taskContext: TaskContext): TaskAIData {
    const categoryDurations: { [key: string]: number } = {
      'planning': 30,
      'coding': 60,
      'testing': 45,
      'documentation': 35,
      'meeting': 30,
      'research': 90,
      'design': 75,
      'review': 20,
      'general': 25
    };

    return {
      estimatedDuration: categoryDurations[taskContext.category] || 25,
      complexityScore: 0.5,
      tags: [taskContext.category],
      suggestedTimeSlots: ['morning'],
      optimizationTips: ['Break into smaller chunks', 'Use the Pomodoro technique'],
      relatedTasks: [],
      urgency: taskContext.priority === 'high' ? 'high' : 'medium',
      cognitiveLoad: 0.5,
      prerequisites: [],
    };
  }

  /**
   * Fallback recommendations
   */
  private getFallbackRecommendations() {
    return {
      timeSlots: ['morning'],
      tips: ['Break the task into smaller chunks', 'Use focus techniques'],
      relatedTasks: [],
      prerequisites: []
    };
  }
}

export const aiService = new AIService();