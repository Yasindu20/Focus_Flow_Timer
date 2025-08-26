"use strict";
/**
 * Analytics Service for Focus Flow Timer
 * Handles comprehensive user analytics, insights, and data export
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.analyticsService = exports.AnalyticsService = void 0;
const admin = __importStar(require("firebase-admin"));
const db = admin.firestore();
class AnalyticsService {
    /**
     * Calculate comprehensive user analytics for a date range
     */
    async calculateUserAnalytics(userId, startDate, endDate) {
        try {
            console.log(`Calculating analytics for user ${userId} from ${startDate.toISOString()} to ${endDate.toISOString()}`);
            // Fetch user data
            const [tasks, sessions] = await Promise.all([
                this.getUserTasks(userId, startDate, endDate),
                this.getUserSessions(userId, startDate, endDate)
            ]);
            // Calculate basic metrics
            const metrics = this.calculateMetrics(tasks, sessions, startDate, endDate);
            // Identify patterns
            const patterns = await this.identifyPatterns(tasks, sessions);
            // Generate recommendations
            const recommendations = await this.generateRecommendations(metrics, patterns);
            // Calculate time distributions
            const timeDistribution = this.calculateTimeDistribution(tasks, sessions);
            // Calculate efficiency scores
            const efficiency = this.calculateEfficiencyScores(tasks, sessions, metrics);
            const analytics = {
                userId,
                period: { start: startDate, end: endDate },
                metrics,
                patterns,
                recommendations,
                timeDistribution,
                efficiency,
                lastUpdated: new Date()
            };
            // Store analytics for future reference
            await this.storeAnalytics(userId, analytics);
            return analytics;
        }
        catch (error) {
            console.error('Analytics calculation error:', error);
            throw error;
        }
    }
    /**
     * Generate productivity insights with AI analysis
     */
    async generateProductivityInsights(userId) {
        try {
            // Get recent analytics data
            const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
            const now = new Date();
            const analytics = await this.calculateUserAnalytics(userId, thirtyDaysAgo, now);
            // Generate insights using AI
            const insights = await this.generateAIInsights(analytics);
            // Calculate trends
            const trends = await this.calculateTrends(userId, analytics);
            // Generate personalized suggestions
            const suggestions = await this.generatePersonalizedSuggestions(analytics);
            // Identify achievements
            const achievements = this.identifyAchievements(analytics);
            return {
                insights,
                trends,
                suggestions,
                achievements
            };
        }
        catch (error) {
            console.error('Productivity insights error:', error);
            throw error;
        }
    }
    /**
     * Export user data in various formats
     */
    async exportUserData(userId, format, startDate, endDate) {
        try {
            const start = startDate ? new Date(startDate) : new Date(Date.now() - 90 * 24 * 60 * 60 * 1000);
            const end = endDate ? new Date(endDate) : new Date();
            // Gather all user data
            const [tasks, sessions, analytics] = await Promise.all([
                this.getUserTasks(userId, start, end),
                this.getUserSessions(userId, start, end),
                this.getUserAnalytics(userId, start, end)
            ]);
            const exportData = {
                user: userId,
                exportedAt: new Date().toISOString(),
                period: { start: start.toISOString(), end: end.toISOString() },
                tasks,
                sessions,
                analytics,
                summary: {
                    totalTasks: tasks.length,
                    completedTasks: tasks.filter(t => t.isCompleted).length,
                    totalSessions: sessions.length,
                    totalTimeSpent: sessions.reduce((sum, s) => sum + (s.duration || 0), 0)
                }
            };
            // Generate export file
            const filename = `focus-flow-export-${userId}-${Date.now()}.${format}`;
            let content;
            switch (format) {
                case 'json':
                    content = JSON.stringify(exportData, null, 2);
                    break;
                case 'csv':
                    content = this.convertToCSV(exportData);
                    break;
                case 'xlsx':
                    content = await this.convertToExcel(exportData);
                    break;
                default:
                    throw new Error('Unsupported export format');
            }
            // Upload to Firebase Storage
            const bucket = admin.storage().bucket();
            const file = bucket.file(`exports/${userId}/${filename}`);
            await file.save(content, {
                metadata: {
                    contentType: this.getContentType(format),
                    metadata: {
                        userId,
                        exportedAt: new Date().toISOString(),
                        format
                    }
                }
            });
            // Generate signed URL (valid for 24 hours)
            const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);
            const [downloadUrl] = await file.getSignedUrl({
                action: 'read',
                expires: expiresAt
            });
            return {
                downloadUrl,
                filename,
                size: Buffer.byteLength(content),
                expiresAt
            };
        }
        catch (error) {
            console.error('Data export error:', error);
            throw error;
        }
    }
    /**
     * Aggregate daily analytics for all users
     */
    async aggregateDailyAnalytics(date) {
        try {
            console.log(`Aggregating daily analytics for ${date.toDateString()}`);
            const usersSnapshot = await db.collection('users').get();
            const aggregationPromises = usersSnapshot.docs.map(async (userDoc) => {
                try {
                    const userId = userDoc.id;
                    const startOfDay = new Date(date);
                    startOfDay.setHours(0, 0, 0, 0);
                    const endOfDay = new Date(date);
                    endOfDay.setHours(23, 59, 59, 999);
                    const dailyAnalytics = await this.calculateUserAnalytics(userId, startOfDay, endOfDay);
                    // Store daily summary
                    await db.collection('users').doc(userId).collection('daily_analytics').doc(date.toISOString().split('T')[0]).set(Object.assign(Object.assign({}, dailyAnalytics), { aggregatedAt: admin.firestore.FieldValue.serverTimestamp() }));
                }
                catch (error) {
                    console.error(`Failed to aggregate analytics for user ${userDoc.id}:`, error);
                }
            });
            await Promise.all(aggregationPromises);
            console.log('Daily analytics aggregation completed');
        }
        catch (error) {
            console.error('Daily aggregation error:', error);
            throw error;
        }
    }
    /**
     * Generate weekly insights for a user
     */
    async generateWeeklyInsights(userId) {
        try {
            const now = new Date();
            const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
            const weeklyAnalytics = await this.calculateUserAnalytics(userId, weekAgo, now);
            const insights = await this.generateProductivityInsights(userId);
            // Store weekly insights
            await db.collection('users').doc(userId).collection('weekly_insights').add(Object.assign(Object.assign({}, insights), { analytics: weeklyAnalytics, weekOf: weekAgo, generatedAt: admin.firestore.FieldValue.serverTimestamp() }));
        }
        catch (error) {
            console.error(`Weekly insights generation failed for user ${userId}:`, error);
        }
    }
    /**
     * Update task statistics when tasks are created/completed
     */
    async updateTaskStatistics(userId, action, taskData) {
        try {
            const userRef = db.collection('users').doc(userId);
            const statsRef = userRef.collection('statistics').doc('current');
            await db.runTransaction(async (transaction) => {
                const statsDoc = await transaction.get(statsRef);
                const currentStats = statsDoc.data() || {};
                const updates = {
                    lastUpdated: admin.firestore.FieldValue.serverTimestamp()
                };
                if (action === 'created') {
                    updates.totalTasksCreated = admin.firestore.FieldValue.increment(1);
                    updates.tasksCreatedToday = admin.firestore.FieldValue.increment(1);
                }
                else if (action === 'completed' && taskData) {
                    updates.totalTasksCompleted = admin.firestore.FieldValue.increment(1);
                    updates.tasksCompletedToday = admin.firestore.FieldValue.increment(1);
                    if (taskData.actualDuration) {
                        updates.totalTimeSpent = admin.firestore.FieldValue.increment(taskData.actualDuration);
                    }
                    if (taskData.estimatedDuration && taskData.actualDuration) {
                        const accuracy = 1 - Math.abs(taskData.actualDuration - taskData.estimatedDuration) / taskData.estimatedDuration;
                        updates.estimationAccuracySum = admin.firestore.FieldValue.increment(accuracy);
                        updates.estimatedTasksCount = admin.firestore.FieldValue.increment(1);
                    }
                }
                transaction.set(statsRef, updates, { merge: true });
            });
        }
        catch (error) {
            console.error('Task statistics update error:', error);
        }
    }
    /**
     * Generate completion insights when a task is completed
     */
    async generateCompletionInsights(userId, taskData) {
        try {
            const insights = [];
            // Estimation accuracy insight
            if (taskData.estimatedDuration && taskData.actualDuration) {
                const accuracy = 1 - Math.abs(taskData.actualDuration - taskData.estimatedDuration) / taskData.estimatedDuration;
                if (accuracy > 0.9) {
                    insights.push({
                        type: 'estimation_accuracy',
                        message: 'Great time estimation! You completed this task very close to your estimate.',
                        score: accuracy,
                        taskId: taskData.id
                    });
                }
                else if (accuracy < 0.5) {
                    insights.push({
                        type: 'estimation_improvement',
                        message: 'Consider breaking down complex tasks for better time estimates.',
                        score: accuracy,
                        taskId: taskData.id
                    });
                }
            }
            // Focus session insight
            if (taskData.pomodoroSessions > 0) {
                insights.push({
                    type: 'focus_session',
                    message: `Completed ${taskData.pomodoroSessions} focus sessions for this task.`,
                    sessions: taskData.pomodoroSessions,
                    taskId: taskData.id
                });
            }
            // Store insights
            if (insights.length > 0) {
                await db.collection('users').doc(userId).collection('task_insights').add({
                    taskId: taskData.id,
                    insights,
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
                });
            }
        }
        catch (error) {
            console.error('Completion insights error:', error);
        }
    }
    // Private helper methods
    async getUserTasks(userId, startDate, endDate) {
        const tasksSnapshot = await db.collection('users').doc(userId).collection('tasks')
            .where('createdAt', '>=', startDate)
            .where('createdAt', '<=', endDate)
            .get();
        return tasksSnapshot.docs.map(doc => (Object.assign({ id: doc.id }, doc.data())));
    }
    async getUserSessions(userId, startDate, endDate) {
        const sessionsSnapshot = await db.collection('users').doc(userId).collection('sessions')
            .where('startTime', '>=', startDate)
            .where('startTime', '<=', endDate)
            .get();
        return sessionsSnapshot.docs.map(doc => (Object.assign({ id: doc.id }, doc.data())));
    }
    calculateMetrics(tasks, sessions, startDate, endDate) {
        const completedTasks = tasks.filter(t => t.isCompleted);
        const totalTimeSpent = sessions.reduce((sum, s) => sum + (s.duration || 0), 0);
        const daysDiff = Math.max(1, Math.ceil((endDate.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24)));
        const estimationAccuracySum = completedTasks.reduce((sum, task) => {
            if (task.estimatedDuration && task.actualDuration) {
                return sum + (1 - Math.abs(task.actualDuration - task.estimatedDuration) / task.estimatedDuration);
            }
            return sum;
        }, 0);
        const tasksWithEstimates = completedTasks.filter(t => t.estimatedDuration && t.actualDuration).length;
        return {
            totalTasks: tasks.length,
            completedTasks: completedTasks.length,
            totalTimeSpent,
            averageTimePerTask: completedTasks.length > 0 ? totalTimeSpent / completedTasks.length : 0,
            tasksPerDay: tasks.length / daysDiff,
            focusTime: totalTimeSpent * 0.8,
            breakTime: totalTimeSpent * 0.2,
            productivityScore: completedTasks.length > 0 ? completedTasks.length / tasks.length : 0,
            estimationAccuracy: tasksWithEstimates > 0 ? estimationAccuracySum / tasksWithEstimates : 0
        };
    }
    async identifyPatterns(tasks, sessions) {
        const patterns = [];
        // Time-based patterns
        const hourlyDistribution = {};
        sessions.forEach(session => {
            if (session.startTime) {
                const hour = new Date(session.startTime.toDate()).getHours();
                hourlyDistribution[hour] = (hourlyDistribution[hour] || 0) + 1;
            }
        });
        // Find peak hours
        const peakHour = Object.entries(hourlyDistribution)
            .sort(([, a], [, b]) => b - a)[0];
        if (peakHour) {
            patterns.push({
                type: 'time',
                description: `Most productive during ${peakHour[0]}:00 hour`,
                strength: Number(peakHour[1]) / sessions.length,
                confidence: 0.8,
                data: { hour: Number(peakHour[0]), sessions: Number(peakHour[1]) }
            });
        }
        // Category patterns
        const categoryPerformance = {};
        tasks.forEach(task => {
            const category = task.category || 'general';
            if (!categoryPerformance[category]) {
                categoryPerformance[category] = { total: 0, completed: 0 };
            }
            categoryPerformance[category].total++;
            if (task.isCompleted) {
                categoryPerformance[category].completed++;
            }
        });
        // Find best-performing category
        const bestCategory = Object.entries(categoryPerformance)
            .map(([cat, perf]) => ({ category: cat, rate: perf.completed / perf.total }))
            .sort((a, b) => b.rate - a.rate)[0];
        if (bestCategory && bestCategory.rate > 0.7) {
            patterns.push({
                type: 'category',
                description: `Highest completion rate in ${bestCategory.category} tasks`,
                strength: bestCategory.rate,
                confidence: 0.7,
                data: { category: bestCategory.category, rate: bestCategory.rate }
            });
        }
        return patterns;
    }
    async generateRecommendations(metrics, patterns) {
        const recommendations = [];
        // Estimation accuracy recommendation
        if (metrics.estimationAccuracy < 0.7) {
            recommendations.push({
                type: 'estimation',
                title: 'Improve Time Estimation',
                description: 'Your time estimates could be more accurate. Try breaking tasks into smaller chunks.',
                impact: 'high',
                effort: 'medium'
            });
        }
        // Productivity score recommendation
        if (metrics.productivityScore < 0.6) {
            recommendations.push({
                type: 'focusTime',
                title: 'Increase Task Completion Rate',
                description: 'Focus on completing started tasks before beginning new ones.',
                impact: 'high',
                effort: 'low'
            });
        }
        // Break time recommendation
        if (metrics.breakTime / metrics.totalTimeSpent < 0.15) {
            recommendations.push({
                type: 'breaks',
                title: 'Take Regular Breaks',
                description: 'Regular breaks can improve focus and prevent burnout.',
                impact: 'medium',
                effort: 'low'
            });
        }
        return recommendations;
    }
    calculateTimeDistribution(tasks, sessions) {
        const byCategory = {};
        const byHour = {};
        const byDay = {};
        // Category distribution
        tasks.forEach(task => {
            const category = task.category || 'general';
            const duration = task.actualDuration || task.estimatedDuration || 0;
            byCategory[category] = (byCategory[category] || 0) + duration;
        });
        // Hour distribution
        sessions.forEach(session => {
            if (session.startTime) {
                const hour = new Date(session.startTime.toDate()).getHours();
                const duration = session.duration || 0;
                byHour[hour] = (byHour[hour] || 0) + duration;
            }
        });
        // Day distribution
        sessions.forEach(session => {
            if (session.startTime) {
                const day = new Date(session.startTime.toDate()).getDay();
                const duration = session.duration || 0;
                byDay[day] = (byDay[day] || 0) + duration;
            }
        });
        return { byCategory, byHour, byDay };
    }
    calculateEfficiencyScores(tasks, sessions, metrics) {
        return {
            overall: metrics.productivityScore,
            estimation: metrics.estimationAccuracy,
            focus: Math.min(1, metrics.focusTime / (metrics.focusTime + metrics.breakTime)),
            consistency: this.calculateConsistencyScore(sessions),
            timeManagement: Math.min(1, metrics.averageTimePerTask / (60 * 60 * 1000)) // Normalize to 1 hour
        };
    }
    calculateConsistencyScore(sessions) {
        if (sessions.length < 2)
            return 0;
        const dailySessions = {};
        sessions.forEach(session => {
            if (session.startTime) {
                const date = new Date(session.startTime.toDate()).toDateString();
                dailySessions[date] = (dailySessions[date] || 0) + 1;
            }
        });
        const sessionCounts = Object.values(dailySessions);
        const mean = sessionCounts.reduce((a, b) => a + b, 0) / sessionCounts.length;
        const variance = sessionCounts.reduce((sum, count) => sum + Math.pow(count - mean, 2), 0) / sessionCounts.length;
        const stdDev = Math.sqrt(variance);
        // Lower standard deviation = higher consistency
        return Math.max(0, 1 - stdDev / mean);
    }
    async generateAIInsights(analytics) {
        // This would use AI to generate personalized insights
        // For now, return static insights based on patterns
        const insights = [];
        if (analytics.metrics.productivityScore > 0.8) {
            insights.push("You're maintaining excellent task completion rates!");
        }
        if (analytics.patterns.some(p => p.type === 'time')) {
            const timePattern = analytics.patterns.find(p => p.type === 'time');
            if (timePattern) {
                insights.push(`You're most productive during ${timePattern.description}`);
            }
        }
        return insights;
    }
    async calculateTrends(userId, currentAnalytics) {
        // This would compare current analytics with historical data
        return [
            { metric: 'productivity', trend: 'up', value: currentAnalytics.metrics.productivityScore },
            { metric: 'estimation', trend: 'stable', value: currentAnalytics.metrics.estimationAccuracy }
        ];
    }
    async generatePersonalizedSuggestions(analytics) {
        const suggestions = [];
        if (analytics.efficiency.estimation < 0.7) {
            suggestions.push("Try the planning poker technique for better time estimation");
        }
        if (analytics.efficiency.focus < 0.6) {
            suggestions.push("Consider using the Pomodoro technique with longer focus blocks");
        }
        return suggestions;
    }
    identifyAchievements(analytics) {
        const achievements = [];
        if (analytics.metrics.completedTasks >= 10) {
            achievements.push("Task Master: Completed 10+ tasks!");
        }
        if (analytics.efficiency.estimation > 0.9) {
            achievements.push("Time Oracle: Achieved 90%+ estimation accuracy!");
        }
        return achievements;
    }
    async storeAnalytics(userId, analytics) {
        const analyticsRef = db.collection('users').doc(userId).collection('analytics').doc('current');
        await analyticsRef.set(Object.assign(Object.assign({}, analytics), { storedAt: admin.firestore.FieldValue.serverTimestamp() }));
    }
    async getUserAnalytics(userId, startDate, endDate) {
        const analyticsSnapshot = await db.collection('users').doc(userId).collection('analytics')
            .where('lastUpdated', '>=', startDate)
            .where('lastUpdated', '<=', endDate)
            .get();
        return analyticsSnapshot.docs.map(doc => doc.data());
    }
    convertToCSV(data) {
        // Simple CSV conversion - would be more sophisticated in production
        const tasks = data.tasks || [];
        let csv = 'Title,Category,Priority,Status,Created,Completed,Estimated Duration,Actual Duration\n';
        tasks.forEach((task) => {
            csv += `"${task.title}","${task.category}","${task.priority}","${task.status}","${task.createdAt}","${task.completedAt}","${task.estimatedDuration}","${task.actualDuration}"\n`;
        });
        return csv;
    }
    async convertToExcel(data) {
        // Would use a library like xlsx to create Excel files
        // For now, return JSON as buffer
        return Buffer.from(JSON.stringify(data, null, 2));
    }
    getContentType(format) {
        switch (format) {
            case 'json': return 'application/json';
            case 'csv': return 'text/csv';
            case 'xlsx': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
            default: return 'application/octet-stream';
        }
    }
}
exports.AnalyticsService = AnalyticsService;
exports.analyticsService = new AnalyticsService();
//# sourceMappingURL=analyticsService.js.map