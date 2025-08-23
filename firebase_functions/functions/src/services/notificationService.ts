/**
 * Notification Service for Focus Flow Timer
 * Handles push notifications, email notifications, and real-time alerts
 */

import * as admin from 'firebase-admin';
import * as nodemailer from 'nodemailer';

const db = admin.firestore();
const messaging = admin.messaging();

export interface NotificationConfig {
  userId: string;
  pushEnabled: boolean;
  emailEnabled: boolean;
  inAppEnabled: boolean;
  preferences: {
    taskReminders: boolean;
    deadlineAlerts: boolean;
    completionCelebrations: boolean;
    weeklyReports: boolean;
    achievementNotifications: boolean;
    focusSessionAlerts: boolean;
  };
  quiet_hours: {
    enabled: boolean;
    start: string; // HH:mm format
    end: string;   // HH:mm format
    timezone: string;
  };
}

export interface NotificationTemplate {
  id: string;
  type: 'push' | 'email' | 'in_app';
  title: string;
  body: string;
  data?: Record<string, any>;
  action?: {
    type: 'deep_link' | 'url' | 'callback';
    value: string;
  };
}

export class NotificationService {
  private emailTransporter: nodemailer.Transporter;

  constructor() {
    // Initialize email transporter
    this.emailTransporter = nodemailer.createTransporter({
      service: 'gmail',
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS
      }
    });
  }

  /**
   * Send deadline reminders for upcoming tasks
   */
  async sendDeadlineReminders(targetDate: Date): Promise<void> {
    try {
      console.log(`Sending deadline reminders for ${targetDate.toDateString()}`);

      // Query tasks with deadlines approaching
      const startOfDay = new Date(targetDate);
      startOfDay.setHours(0, 0, 0, 0);
      const endOfDay = new Date(targetDate);
      endOfDay.setHours(23, 59, 59, 999);

      const usersSnapshot = await db.collection('users').get();
      
      const reminderPromises = usersSnapshot.docs.map(async (userDoc) => {
        try {
          const userId = userDoc.id;
          
          // Get user's notification preferences
          const notificationConfig = await this.getUserNotificationConfig(userId);
          if (!notificationConfig.preferences.deadlineAlerts) {
            return;
          }

          // Check quiet hours
          if (this.isQuietHours(notificationConfig.quiet_hours)) {
            return;
          }

          // Get tasks with approaching deadlines
          const tasksSnapshot = await db.collection('users').doc(userId).collection('tasks')
            .where('dueDate', '>=', startOfDay)
            .where('dueDate', '<=', endOfDay)
            .where('isCompleted', '==', false)
            .get();

          if (tasksSnapshot.empty) {
            return;
          }

          const tasks = tasksSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
          
          // Send notifications based on preferences
          const notifications: NotificationTemplate[] = tasks.map(task => ({
            id: `deadline_${task.id}`,
            type: 'push',
            title: '📅 Task Deadline Reminder',
            body: `"${task.title}" is due ${this.formatDeadline(task.dueDate)}`,
            data: {
              type: 'deadline_reminder',
              taskId: task.id,
              dueDate: task.dueDate
            },
            action: {
              type: 'deep_link',
              value: `/tasks/${task.id}`
            }
          }));

          await this.sendNotifications(userId, notifications, notificationConfig);

        } catch (error) {
          console.error(`Failed to send deadline reminders for user ${userDoc.id}:`, error);
        }
      });

      await Promise.all(reminderPromises);
      console.log('Deadline reminders completed');

    } catch (error) {
      console.error('Deadline reminders error:', error);
      throw error;
    }
  }

  /**
   * Send completion celebration notification
   */
  async sendCompletionNotification(userId: string, taskData: any): Promise<void> {
    try {
      const notificationConfig = await this.getUserNotificationConfig(userId);
      
      if (!notificationConfig.preferences.completionCelebrations) {
        return;
      }

      if (this.isQuietHours(notificationConfig.quiet_hours)) {
        return;
      }

      // Generate celebration message based on task completion
      const celebration = this.generateCelebrationMessage(taskData);
      
      const notification: NotificationTemplate = {
        id: `completion_${taskData.id}`,
        type: 'push',
        title: '🎉 Task Completed!',
        body: celebration.message,
        data: {
          type: 'task_completion',
          taskId: taskData.id,
          completedAt: new Date().toISOString(),
          streak: celebration.streak
        },
        action: {
          type: 'deep_link',
          value: '/analytics'
        }
      };

      await this.sendNotifications(userId, [notification], notificationConfig);

    } catch (error) {
      console.error('Completion notification error:', error);
    }
  }

  /**
   * Send focus session alerts
   */
  async sendFocusSessionAlert(userId: string, sessionType: 'start' | 'break' | 'complete', sessionData: any): Promise<void> {
    try {
      const notificationConfig = await this.getUserNotificationConfig(userId);
      
      if (!notificationConfig.preferences.focusSessionAlerts) {
        return;
      }

      let notification: NotificationTemplate;

      switch (sessionType) {
        case 'start':
          notification = {
            id: `focus_start_${sessionData.id}`,
            type: 'in_app',
            title: '🎯 Focus Session Started',
            body: `Stay focused for ${sessionData.duration} minutes!`,
            data: { type: 'focus_start', sessionId: sessionData.id }
          };
          break;
        
        case 'break':
          notification = {
            id: `focus_break_${sessionData.id}`,
            type: 'push',
            title: '☕ Time for a Break',
            body: `Great work! Take a ${sessionData.breakDuration} minute break.`,
            data: { type: 'focus_break', sessionId: sessionData.id }
          };
          break;
        
        case 'complete':
          notification = {
            id: `focus_complete_${sessionData.id}`,
            type: 'push',
            title: '✅ Focus Session Complete',
            body: `You completed a ${sessionData.duration} minute focus session!`,
            data: { type: 'focus_complete', sessionId: sessionData.id }
          };
          break;
      }

      await this.sendNotifications(userId, [notification], notificationConfig);

    } catch (error) {
      console.error('Focus session alert error:', error);
    }
  }

  /**
   * Send weekly productivity report
   */
  async sendWeeklyReport(userId: string, reportData: any): Promise<void> {
    try {
      const notificationConfig = await this.getUserNotificationConfig(userId);
      
      if (!notificationConfig.preferences.weeklyReports) {
        return;
      }

      // Send email report
      if (notificationConfig.emailEnabled) {
        await this.sendWeeklyEmailReport(userId, reportData);
      }

      // Send push notification summary
      if (notificationConfig.pushEnabled) {
        const notification: NotificationTemplate = {
          id: `weekly_report_${Date.now()}`,
          type: 'push',
          title: '📊 Your Weekly Report is Ready',
          body: `You completed ${reportData.tasksCompleted} tasks this week!`,
          data: {
            type: 'weekly_report',
            tasksCompleted: reportData.tasksCompleted,
            totalTime: reportData.totalTime
          },
          action: {
            type: 'deep_link',
            value: '/analytics/weekly'
          }
        };

        await this.sendNotifications(userId, [notification], notificationConfig);
      }

    } catch (error) {
      console.error('Weekly report notification error:', error);
    }
  }

  /**
   * Send achievement notification
   */
  async sendAchievementNotification(userId: string, achievement: any): Promise<void> {
    try {
      const notificationConfig = await this.getUserNotificationConfig(userId);
      
      if (!notificationConfig.preferences.achievementNotifications) {
        return;
      }

      const notification: NotificationTemplate = {
        id: `achievement_${achievement.id}`,
        type: 'push',
        title: '🏆 Achievement Unlocked!',
        body: `${achievement.title}: ${achievement.description}`,
        data: {
          type: 'achievement',
          achievementId: achievement.id,
          title: achievement.title
        },
        action: {
          type: 'deep_link',
          value: '/achievements'
        }
      };

      await this.sendNotifications(userId, [notification], notificationConfig);

      // Store achievement notification in user's history
      await db.collection('users').doc(userId).collection('notifications').add({
        ...notification,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        read: false
      });

    } catch (error) {
      console.error('Achievement notification error:', error);
    }
  }

  /**
   * Send custom notification
   */
  async sendCustomNotification(userId: string, notification: NotificationTemplate): Promise<void> {
    try {
      const notificationConfig = await this.getUserNotificationConfig(userId);
      await this.sendNotifications(userId, [notification], notificationConfig);
    } catch (error) {
      console.error('Custom notification error:', error);
      throw error;
    }
  }

  /**
   * Configure user notification preferences
   */
  async configureNotifications(userId: string, config: Partial<NotificationConfig>): Promise<void> {
    try {
      const notificationRef = db.collection('users').doc(userId).collection('settings').doc('notifications');
      
      await notificationRef.set({
        ...config,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });

    } catch (error) {
      console.error('Notification configuration error:', error);
      throw error;
    }
  }

  /**
   * Register device token for push notifications
   */
  async registerDeviceToken(userId: string, token: string, deviceInfo: any): Promise<void> {
    try {
      const deviceRef = db.collection('users').doc(userId).collection('devices').doc(token);
      
      await deviceRef.set({
        token,
        deviceInfo,
        registeredAt: admin.firestore.FieldValue.serverTimestamp(),
        lastSeen: admin.firestore.FieldValue.serverTimestamp(),
        active: true
      });

    } catch (error) {
      console.error('Device token registration error:', error);
      throw error;
    }
  }

  /**
   * Get user's in-app notifications
   */
  async getUserNotifications(userId: string, limit: number = 20, unreadOnly: boolean = false): Promise<any[]> {
    try {
      let query = db.collection('users').doc(userId).collection('notifications')
        .orderBy('sentAt', 'desc')
        .limit(limit);

      if (unreadOnly) {
        query = query.where('read', '==', false);
      }

      const snapshot = await query.get();
      return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    } catch (error) {
      console.error('Get notifications error:', error);
      throw error;
    }
  }

  /**
   * Mark notification as read
   */
  async markNotificationRead(userId: string, notificationId: string): Promise<void> {
    try {
      await db.collection('users').doc(userId).collection('notifications').doc(notificationId).update({
        read: true,
        readAt: admin.firestore.FieldValue.serverTimestamp()
      });
    } catch (error) {
      console.error('Mark notification read error:', error);
      throw error;
    }
  }

  /**
   * Clear all notifications for user
   */
  async clearNotifications(userId: string): Promise<void> {
    try {
      const batch = db.batch();
      const notifications = await db.collection('users').doc(userId).collection('notifications').get();
      
      notifications.docs.forEach(doc => {
        batch.delete(doc.ref);
      });

      await batch.commit();
    } catch (error) {
      console.error('Clear notifications error:', error);
      throw error;
    }
  }

  // Private helper methods

  private async getUserNotificationConfig(userId: string): Promise<NotificationConfig> {
    const doc = await db.collection('users').doc(userId).collection('settings').doc('notifications').get();
    
    if (doc.exists) {
      return doc.data() as NotificationConfig;
    }

    // Return default configuration
    return {
      userId,
      pushEnabled: true,
      emailEnabled: false,
      inAppEnabled: true,
      preferences: {
        taskReminders: true,
        deadlineAlerts: true,
        completionCelebrations: true,
        weeklyReports: false,
        achievementNotifications: true,
        focusSessionAlerts: true
      },
      quiet_hours: {
        enabled: false,
        start: '22:00',
        end: '08:00',
        timezone: 'UTC'
      }
    };
  }

  private async sendNotifications(userId: string, notifications: NotificationTemplate[], config: NotificationConfig): Promise<void> {
    const promises = notifications.map(async (notification) => {
      try {
        // Send push notification
        if (config.pushEnabled && (notification.type === 'push' || notification.type === 'in_app')) {
          await this.sendPushNotification(userId, notification);
        }

        // Send email notification
        if (config.emailEnabled && notification.type === 'email') {
          await this.sendEmailNotification(userId, notification);
        }

        // Store in-app notification
        if (config.inAppEnabled) {
          await this.storeInAppNotification(userId, notification);
        }

      } catch (error) {
        console.error(`Failed to send notification ${notification.id}:`, error);
      }
    });

    await Promise.all(promises);
  }

  private async sendPushNotification(userId: string, notification: NotificationTemplate): Promise<void> {
    try {
      // Get user's device tokens
      const devicesSnapshot = await db.collection('users').doc(userId).collection('devices')
        .where('active', '==', true)
        .get();

      if (devicesSnapshot.empty) {
        console.log(`No active devices found for user ${userId}`);
        return;
      }

      const tokens = devicesSnapshot.docs.map(doc => doc.data().token);

      const message: admin.messaging.MulticastMessage = {
        notification: {
          title: notification.title,
          body: notification.body
        },
        data: notification.data ? Object.fromEntries(
          Object.entries(notification.data).map(([k, v]) => [k, String(v)])
        ) : undefined,
        tokens
      };

      const response = await messaging.sendMulticast(message);

      // Handle failed tokens
      if (response.failureCount > 0) {
        const failedTokens: string[] = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            failedTokens.push(tokens[idx]);
          }
        });

        // Deactivate failed tokens
        const deactivatePromises = failedTokens.map(token => 
          db.collection('users').doc(userId).collection('devices').doc(token).update({ active: false })
        );
        await Promise.all(deactivatePromises);
      }

    } catch (error) {
      console.error('Push notification error:', error);
      throw error;
    }
  }

  private async sendEmailNotification(userId: string, notification: NotificationTemplate): Promise<void> {
    try {
      // Get user's email
      const userDoc = await db.collection('users').doc(userId).get();
      const userData = userDoc.data();
      
      if (!userData?.email) {
        console.warn(`No email found for user ${userId}`);
        return;
      }

      const mailOptions = {
        from: process.env.EMAIL_USER,
        to: userData.email,
        subject: notification.title,
        html: this.generateEmailHTML(notification)
      };

      await this.emailTransporter.sendMail(mailOptions);

    } catch (error) {
      console.error('Email notification error:', error);
      throw error;
    }
  }

  private async storeInAppNotification(userId: string, notification: NotificationTemplate): Promise<void> {
    await db.collection('users').doc(userId).collection('notifications').add({
      ...notification,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      read: false
    });
  }

  private isQuietHours(quietHours: NotificationConfig['quiet_hours']): boolean {
    if (!quietHours.enabled) {
      return false;
    }

    const now = new Date();
    const currentTime = now.getHours() * 60 + now.getMinutes();
    
    const [startHour, startMin] = quietHours.start.split(':').map(Number);
    const [endHour, endMin] = quietHours.end.split(':').map(Number);
    
    const startTime = startHour * 60 + startMin;
    const endTime = endHour * 60 + endMin;

    if (startTime <= endTime) {
      // Same day range
      return currentTime >= startTime && currentTime <= endTime;
    } else {
      // Overnight range
      return currentTime >= startTime || currentTime <= endTime;
    }
  }

  private formatDeadline(dueDate: any): string {
    const date = dueDate.toDate ? dueDate.toDate() : new Date(dueDate);
    const now = new Date();
    const diffHours = Math.floor((date.getTime() - now.getTime()) / (1000 * 60 * 60));

    if (diffHours < 1) {
      return 'in less than an hour';
    } else if (diffHours < 24) {
      return `in ${diffHours} hours`;
    } else {
      const diffDays = Math.floor(diffHours / 24);
      return `in ${diffDays} day${diffDays > 1 ? 's' : ''}`;
    }
  }

  private generateCelebrationMessage(taskData: any): { message: string; streak: number } {
    const messages = [
      `Great job completing "${taskData.title}"!`,
      `You crushed it! "${taskData.title}" is done! 💪`,
      `Another one bites the dust! "${taskData.title}" completed! ✨`,
      `Way to go! "${taskData.title}" is checked off your list! 🎯`,
      `Outstanding work on "${taskData.title}"! Keep it up! 🚀`
    ];

    // Simple streak calculation (would be more sophisticated in production)
    const streak = Math.floor(Math.random() * 10) + 1;
    
    return {
      message: messages[Math.floor(Math.random() * messages.length)],
      streak
    };
  }

  private async sendWeeklyEmailReport(userId: string, reportData: any): Promise<void> {
    try {
      const userDoc = await db.collection('users').doc(userId).get();
      const userData = userDoc.data();
      
      if (!userData?.email) {
        return;
      }

      const htmlContent = this.generateWeeklyReportHTML(reportData);

      const mailOptions = {
        from: process.env.EMAIL_USER,
        to: userData.email,
        subject: '📊 Your Weekly Focus Flow Report',
        html: htmlContent
      };

      await this.emailTransporter.sendMail(mailOptions);

    } catch (error) {
      console.error('Weekly email report error:', error);
    }
  }

  private generateEmailHTML(notification: NotificationTemplate): string {
    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>${notification.title}</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #6366f1; color: white; padding: 20px; border-radius: 8px; }
          .content { padding: 20px; background: #f9fafb; border-radius: 8px; margin-top: 20px; }
          .footer { text-align: center; padding: 20px; font-size: 12px; color: #666; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>${notification.title}</h1>
          </div>
          <div class="content">
            <p>${notification.body}</p>
          </div>
          <div class="footer">
            <p>Focus Flow Timer - Stay productive, stay focused</p>
          </div>
        </div>
      </body>
      </html>
    `;
  }

  private generateWeeklyReportHTML(reportData: any): string {
    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>Weekly Focus Flow Report</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #6366f1; color: white; padding: 20px; border-radius: 8px; }
          .stats { display: flex; justify-content: space-around; padding: 20px; }
          .stat { text-align: center; }
          .stat-number { font-size: 24px; font-weight: bold; color: #6366f1; }
          .content { padding: 20px; background: #f9fafb; border-radius: 8px; margin-top: 20px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>📊 Your Weekly Report</h1>
            <p>Here's how you performed this week</p>
          </div>
          <div class="stats">
            <div class="stat">
              <div class="stat-number">${reportData.tasksCompleted || 0}</div>
              <div>Tasks Completed</div>
            </div>
            <div class="stat">
              <div class="stat-number">${Math.round((reportData.totalTime || 0) / 60)} min</div>
              <div>Focus Time</div>
            </div>
            <div class="stat">
              <div class="stat-number">${reportData.productivityScore || 0}%</div>
              <div>Productivity Score</div>
            </div>
          </div>
          <div class="content">
            <h3>Key Insights</h3>
            <ul>
              ${(reportData.insights || []).map((insight: string) => `<li>${insight}</li>`).join('')}
            </ul>
          </div>
        </div>
      </body>
      </html>
    `;
  }
}

export const notificationService = new NotificationService();