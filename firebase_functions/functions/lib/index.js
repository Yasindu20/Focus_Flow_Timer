"use strict";
/**
 * Enterprise Cloud Functions for Focus Flow Timer
 * Handles AI task intelligence, analytics, and third-party integrations
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
exports.healthCheck = exports.validateUserPermissions = exports.onUserActivity = exports.onTaskCompleted = exports.onTaskCreated = exports.taskDeadlineNotifications = exports.weeklyInsightsGeneration = exports.dailyAnalyticsAggregation = exports.exportUserData = exports.syncExternalTasks = exports.generateProductivityInsights = exports.calculateUserAnalytics = exports.getTaskRecommendations = exports.processTaskWithAI = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const taskIntelligenceService_1 = require("./services/taskIntelligenceService");
const analyticsService_1 = require("./services/analyticsService");
const integrationService_1 = require("./services/integrationService");
const notificationService_1 = require("./services/notificationService");
const securityService_1 = require("./services/securityService");
// Initialize Firebase Admin SDK
admin.initializeApp();
const db = admin.firestore();
// Configure CORS for enterprise environments
const corsOptions = {
    origin: [
        'https://focus-flow-timer.web.app',
        'https://focus-flow-timer.firebaseapp.com',
        'http://localhost:3000',
        'http://localhost:8080'
    ],
    credentials: true,
    optionsSuccessStatus: 200
};
/**
 * AI Task Intelligence Functions
 */
// Process task with AI enhancement
exports.processTaskWithAI = functions
    .runWith({
    memory: '1GB',
    timeoutSeconds: 60,
})
    .https.onCall(async (data, context) => {
    // Validate authentication
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    // Validate input
    const { title, description, category, priority, userId } = data;
    if (!title || !userId) {
        throw new functions.https.HttpsError('invalid-argument', 'Title and userId are required');
    }
    try {
        console.log(`Processing task with AI for user: ${userId}`);
        // Get user context for better AI processing
        const userDoc = await db.collection('users').doc(userId).get();
        const userData = userDoc.data();
        // Process with AI service
        const aiResult = await taskIntelligenceService_1.taskIntelligenceService.processTask({
            title,
            description: description || '',
            category: category || 'general',
            priority: priority || 'medium',
            userContext: userData
        });
        console.log(`AI processing completed for task: ${title}`);
        return aiResult;
    }
    catch (error) {
        console.error('AI task processing error:', error);
        throw new functions.https.HttpsError('internal', 'AI processing failed');
    }
});
// Get AI-powered task recommendations
exports.getTaskRecommendations = functions
    .runWith({
    memory: '1GB',
    timeoutSeconds: 30,
})
    .https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { userId } = data;
    if (!userId) {
        throw new functions.https.HttpsError('invalid-argument', 'userId is required');
    }
    try {
        // Get user's tasks and analytics
        const tasksSnapshot = await db.collection('users').doc(userId).collection('tasks')
            .where('isCompleted', '==', false)
            .orderBy('createdAt', 'desc')
            .limit(50)
            .get();
        const tasks = tasksSnapshot.docs.map(doc => (Object.assign({ id: doc.id }, doc.data())));
        // Get user analytics for context
        const analyticsDoc = await db.collection('users').doc(userId).collection('analytics')
            .doc('current')
            .get();
        const userAnalytics = analyticsDoc.data();
        // Generate recommendations (simplified without AI)
        const recommendations = tasks
            .slice(0, 5)
            .map(task => (Object.assign(Object.assign({}, task), { recommendationScore: calculateRecommendationScore(task) })))
            .sort((a, b) => b.recommendationScore - a.recommendationScore);
        return recommendations;
    }
    catch (error) {
        console.error('Task recommendations error:', error);
        throw new functions.https.HttpsError('internal', 'Failed to generate recommendations');
    }
});
/**
 * Analytics Functions
 */
// Calculate comprehensive user analytics
exports.calculateUserAnalytics = functions
    .runWith({
    memory: '1GB',
    timeoutSeconds: 60,
})
    .https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { userId, startDate, endDate } = data;
    if (!userId) {
        throw new functions.https.HttpsError('invalid-argument', 'userId is required');
    }
    try {
        const start = startDate ? new Date(startDate) : new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
        const end = endDate ? new Date(endDate) : new Date();
        const analytics = await analyticsService_1.analyticsService.calculateUserAnalytics(userId, start, end);
        return analytics;
    }
    catch (error) {
        console.error('Analytics calculation error:', error);
        throw new functions.https.HttpsError('internal', 'Analytics calculation failed');
    }
});
// Generate productivity insights
exports.generateProductivityInsights = functions
    .runWith({
    memory: '1GB',
    timeoutSeconds: 45,
})
    .https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { userId } = data;
    try {
        const insights = await analyticsService_1.analyticsService.generateProductivityInsights(userId);
        return insights;
    }
    catch (error) {
        console.error('Insights generation error:', error);
        throw new functions.https.HttpsError('internal', 'Insights generation failed');
    }
});
/**
 * Integration Functions
 */
// Sync with external task management services
exports.syncExternalTasks = functions
    .runWith({
    memory: '1GB',
    timeoutSeconds: 120,
})
    .https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { userId, provider, credentials, bidirectional } = data;
    if (!userId || !provider || !credentials) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required parameters');
    }
    try {
        const result = await integrationService_1.integrationService.syncTasks(userId, provider, credentials, bidirectional);
        return result;
    }
    catch (error) {
        console.error('External sync error:', error);
        throw new functions.https.HttpsError('internal', 'External synchronization failed');
    }
});
// Export user data in various formats
exports.exportUserData = functions
    .runWith({
    memory: '2GB',
    timeoutSeconds: 300,
})
    .https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { userId, format, startDate, endDate } = data;
    if (!userId || !format) {
        throw new functions.https.HttpsError('invalid-argument', 'userId and format are required');
    }
    try {
        const exportResult = await analyticsService_1.analyticsService.exportUserData(userId, format, startDate, endDate);
        return exportResult;
    }
    catch (error) {
        console.error('Data export error:', error);
        throw new functions.https.HttpsError('internal', 'Data export failed');
    }
});
/**
 * Automated Functions
 */
// Daily analytics aggregation
exports.dailyAnalyticsAggregation = functions.pubsub
    .schedule('0 2 * * *') // Run daily at 2 AM
    .timeZone('UTC')
    .onRun(async (context) => {
    console.log('Starting daily analytics aggregation');
    try {
        const yesterday = new Date();
        yesterday.setDate(yesterday.getDate() - 1);
        await analyticsService_1.analyticsService.aggregateDailyAnalytics(yesterday);
        console.log('Daily analytics aggregation completed');
    }
    catch (error) {
        console.error('Daily analytics aggregation failed:', error);
    }
});
// Weekly productivity insights generation
exports.weeklyInsightsGeneration = functions.pubsub
    .schedule('0 9 * * 1') // Run weekly on Monday at 9 AM
    .timeZone('UTC')
    .onRun(async (context) => {
    console.log('Starting weekly insights generation');
    try {
        const usersSnapshot = await db.collection('users').get();
        const batchPromises = usersSnapshot.docs.map(async (userDoc) => {
            try {
                await analyticsService_1.analyticsService.generateWeeklyInsights(userDoc.id);
            }
            catch (error) {
                console.error(`Failed to generate insights for user ${userDoc.id}:`, error);
            }
        });
        await Promise.all(batchPromises);
        console.log('Weekly insights generation completed');
    }
    catch (error) {
        console.error('Weekly insights generation failed:', error);
    }
});
// Task deadline notifications
exports.taskDeadlineNotifications = functions.pubsub
    .schedule('0 9,17 * * *') // Run twice daily at 9 AM and 5 PM
    .timeZone('UTC')
    .onRun(async (context) => {
    console.log('Checking for upcoming task deadlines');
    try {
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        await notificationService_1.notificationService.sendDeadlineReminders(tomorrow);
        console.log('Deadline notifications completed');
    }
    catch (error) {
        console.error('Deadline notifications failed:', error);
    }
});
/**
 * Database Triggers
 */
// Task creation trigger - enhance with AI
exports.onTaskCreated = functions.firestore
    .document('users/{userId}/tasks/{taskId}')
    .onCreate(async (snap, context) => {
    const { userId, taskId } = context.params;
    const taskData = snap.data();
    console.log(`Task created: ${taskId} for user: ${userId}`);
    try {
        // Enhance with AI if not already processed
        if (!taskData.aiData || !taskData.aiData.processed) {
            const enhancedData = await taskIntelligenceService_1.taskIntelligenceService.processTask({
                title: taskData.title,
                description: taskData.description || '',
                category: taskData.category || 'general',
                priority: taskData.priority || 'medium',
                userContext: await getUserContext(userId)
            });
            // Update task with AI enhancements
            await snap.ref.update({
                aiData: Object.assign(Object.assign({}, enhancedData), { processed: true, processedAt: admin.firestore.FieldValue.serverTimestamp() })
            });
        }
        // Update user statistics
        await analyticsService_1.analyticsService.updateTaskStatistics(userId, 'created');
    }
    catch (error) {
        console.error('Task creation processing error:', error);
    }
});
// Task completion trigger - update analytics
exports.onTaskCompleted = functions.firestore
    .document('users/{userId}/tasks/{taskId}')
    .onUpdate(async (change, context) => {
    const { userId, taskId } = context.params;
    const beforeData = change.before.data();
    const afterData = change.after.data();
    // Check if task was just completed
    if (!beforeData.isCompleted && afterData.isCompleted) {
        console.log(`Task completed: ${taskId} for user: ${userId}`);
        try {
            // Update analytics
            await analyticsService_1.analyticsService.updateTaskStatistics(userId, 'completed', afterData);
            // Generate completion insights
            await analyticsService_1.analyticsService.generateCompletionInsights(userId, afterData);
            // Send congratulatory notification if appropriate
            await notificationService_1.notificationService.sendCompletionNotification(userId, afterData);
        }
        catch (error) {
            console.error('Task completion processing error:', error);
        }
    }
});
// User activity trigger - update last active
exports.onUserActivity = functions.firestore
    .document('users/{userId}/sessions/{sessionId}')
    .onCreate(async (snap, context) => {
    const { userId } = context.params;
    try {
        // Update user's last active timestamp
        await db.collection('users').doc(userId).update({
            lastActiveAt: admin.firestore.FieldValue.serverTimestamp()
        });
    }
    catch (error) {
        console.error('User activity update error:', error);
    }
});
/**
 * Security Functions
 */
// Validate user permissions
exports.validateUserPermissions = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { resource, action } = data;
    const userId = context.auth.uid;
    try {
        const hasPermission = await securityService_1.securityService.validatePermission(userId, resource, action);
        return { hasPermission };
    }
    catch (error) {
        console.error('Permission validation error:', error);
        throw new functions.https.HttpsError('internal', 'Permission validation failed');
    }
});
// Helper function to calculate recommendation score
function calculateRecommendationScore(task) {
    let score = 0;
    // Priority weight
    const priorityWeights = { low: 1, medium: 2, high: 3, critical: 4 };
    score += (priorityWeights[task.priority] || 2) * 0.4;
    // Recency weight (newer tasks get preference)
    const ageInDays = (Date.now() - new Date(task.createdAt).getTime()) / (1000 * 60 * 60 * 24);
    score += Math.max(0, 1 - ageInDays / 7) * 0.3; // Decay over a week
    // Due date proximity
    if (task.dueDate) {
        const daysUntilDue = (new Date(task.dueDate).getTime() - Date.now()) / (1000 * 60 * 60 * 24);
        if (daysUntilDue <= 3)
            score += 0.3; // Urgent if due within 3 days
    }
    return score;
}
// Helper function to get user context
async function getUserContext(userId) {
    try {
        const userDoc = await db.collection('users').doc(userId).get();
        return userDoc.data() || {};
    }
    catch (error) {
        console.error('Error getting user context:', error);
        return {};
    }
}
/**
 * Health Check Function
 */
exports.healthCheck = functions.https.onRequest((req, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET');
    res.status(200).json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        version: '1.0.0',
        services: {
            firestore: 'operational',
            ai: 'operational',
            analytics: 'operational',
            integrations: 'operational'
        }
    });
});
//# sourceMappingURL=index.js.map