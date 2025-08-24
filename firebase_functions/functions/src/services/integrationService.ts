/**
 * Integration Service for Focus Flow Timer
 * Handles third-party integrations with task management platforms
 */

import * as admin from 'firebase-admin';
import axios from 'axios';
import { aiService } from './aiService';

const db = admin.firestore();

export interface IntegrationConfig {
  provider: string;
  apiKey: string;
  baseUrl?: string;
  credentials: Record<string, any>;
  settings: Record<string, any>;
  isEnabled: boolean;
}

export interface SyncResult {
  success: boolean;
  message: string;
  tasksImported: number;
  tasksExported: number;
  errors: string[];
  timestamp: Date;
}

export interface ExternalTask {
  externalId: string;
  title: string;
  description: string;
  status: string;
  priority?: string;
  category?: string;
  dueDate?: Date;
  assignee?: string;
  labels?: string[];
  url?: string;
  metadata: Record<string, any>;
}

export class IntegrationService {

  /**
   * Sync tasks with external provider
   */
  async syncTasks(userId: string, provider: string, credentials: any, bidirectional: boolean = true): Promise<SyncResult> {
    try {
      console.log(`Starting sync with ${provider} for user ${userId}`);

      const config = await this.getOrCreateIntegrationConfig(userId, provider, credentials);
      
      let tasksImported = 0;
      let tasksExported = 0;
      const errors: string[] = [];

      // Import tasks from external provider
      try {
        const externalTasks = await this.fetchExternalTasks(config);
        tasksImported = await this.importTasks(userId, externalTasks, provider);
      } catch (error) {
        console.error(`Import error for ${provider}:`, error);
        errors.push(`Import failed: ${error.message}`);
      }

      // Export tasks to external provider (if bidirectional)
      if (bidirectional) {
        try {
          const localTasks = await this.getUnexportedTasks(userId, provider);
          tasksExported = await this.exportTasks(config, localTasks);
        } catch (error) {
          console.error(`Export error for ${provider}:`, error);
          errors.push(`Export failed: ${error.message}`);
        }
      }

      // Update sync status
      await this.updateSyncStatus(userId, provider, {
        lastSync: new Date(),
        tasksImported,
        tasksExported,
        errors
      });

      const result: SyncResult = {
        success: errors.length === 0,
        message: errors.length === 0 ? 'Sync completed successfully' : 'Sync completed with errors',
        tasksImported,
        tasksExported,
        errors,
        timestamp: new Date()
      };

      console.log(`Sync completed for ${provider}: imported ${tasksImported}, exported ${tasksExported}`);
      return result;

    } catch (error) {
      console.error(`Sync failed for ${provider}:`, error);
      return {
        success: false,
        message: `Sync failed: ${error.message}`,
        tasksImported: 0,
        tasksExported: 0,
        errors: [error.message],
        timestamp: new Date()
      };
    }
  }

  /**
   * Configure integration for a provider
   */
  async configureIntegration(userId: string, provider: string, config: Partial<IntegrationConfig>): Promise<void> {
    const integrationRef = db.collection('users').doc(userId).collection('integrations').doc(provider);
    
    await integrationRef.set({
      ...config,
      provider,
      configuredAt: admin.firestore.FieldValue.serverTimestamp(),
      lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });

    // Test the connection
    try {
      await this.testConnection({ provider, ...config } as IntegrationConfig);
      await integrationRef.update({ connectionStatus: 'active', lastTested: admin.firestore.FieldValue.serverTimestamp() });
    } catch (error) {
      await integrationRef.update({ connectionStatus: 'failed', lastError: error.message });
      throw error;
    }
  }

  /**
   * Get available integrations
   */
  getAvailableIntegrations(): Array<{
    id: string;
    name: string;
    description: string;
    features: string[];
    requiresAuth: boolean;
    authType: 'oauth' | 'api_key' | 'basic' | 'token';
  }> {
    return [
      {
        id: 'jira',
        name: 'Atlassian Jira',
        description: 'Sync with Jira issues and projects',
        features: ['Import issues', 'Export tasks', 'Status sync', 'Comments'],
        requiresAuth: true,
        authType: 'basic'
      },
      {
        id: 'asana',
        name: 'Asana',
        description: 'Sync with Asana tasks and projects',
        features: ['Import tasks', 'Export tasks', 'Project sync', 'Team collaboration'],
        requiresAuth: true,
        authType: 'oauth'
      },
      {
        id: 'trello',
        name: 'Trello',
        description: 'Sync with Trello boards and cards',
        features: ['Import cards', 'Export tasks', 'Board sync', 'Labels'],
        requiresAuth: true,
        authType: 'api_key'
      },
      {
        id: 'notion',
        name: 'Notion',
        description: 'Sync with Notion databases and pages',
        features: ['Import pages', 'Export tasks', 'Database sync', 'Properties'],
        requiresAuth: true,
        authType: 'oauth'
      },
      {
        id: 'todoist',
        name: 'Todoist',
        description: 'Sync with Todoist tasks and projects',
        features: ['Import tasks', 'Export tasks', 'Project sync', 'Labels & filters'],
        requiresAuth: true,
        authType: 'token'
      },
      {
        id: 'github',
        name: 'GitHub',
        description: 'Sync with GitHub issues and pull requests',
        features: ['Import issues', 'Export tasks', 'Repository sync', 'Milestones'],
        requiresAuth: true,
        authType: 'oauth'
      },
      {
        id: 'linear',
        name: 'Linear',
        description: 'Sync with Linear issues and projects',
        features: ['Import issues', 'Export tasks', 'Status sync', 'Teams'],
        requiresAuth: true,
        authType: 'api_key'
      },
      {
        id: 'slack',
        name: 'Slack',
        description: 'Create tasks from Slack messages and reminders',
        features: ['Message to task', 'Reminder sync', 'Channel integration'],
        requiresAuth: true,
        authType: 'oauth'
      }
    ];
  }

  /**
   * Setup webhook for real-time sync
   */
  async setupWebhook(userId: string, provider: string, events: string[]): Promise<{
    webhookUrl: string;
    webhookId: string;
  }> {
    const webhookUrl = `https://your-cloud-function-url/webhooks/${provider}/${userId}`;
    
    const config = await this.getIntegrationConfig(userId, provider);
    if (!config) {
      throw new Error(`Integration not configured for ${provider}`);
    }

    let webhookId: string;

    switch (provider) {
      case 'jira':
        webhookId = await this.setupJiraWebhook(config, webhookUrl, events);
        break;
      case 'asana':
        webhookId = await this.setupAsanaWebhook(config, webhookUrl, events);
        break;
      case 'github':
        webhookId = await this.setupGitHubWebhook(config, webhookUrl, events);
        break;
      default:
        throw new Error(`Webhooks not supported for ${provider}`);
    }

    // Store webhook info
    await db.collection('users').doc(userId).collection('webhooks').doc(provider).set({
      provider,
      webhookId,
      webhookUrl,
      events,
      setupAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return { webhookUrl, webhookId };
  }

  /**
   * Handle incoming webhook
   */
  async handleWebhook(provider: string, userId: string, payload: any): Promise<void> {
    try {
      console.log(`Received webhook from ${provider} for user ${userId}`);

      const config = await this.getIntegrationConfig(userId, provider);
      if (!config) {
        throw new Error(`Integration not configured for ${provider}`);
      }

      // Verify webhook signature if required
      if (!this.verifyWebhookSignature(provider, payload)) {
        throw new Error('Invalid webhook signature');
      }

      // Process webhook based on provider
      switch (provider) {
        case 'jira':
          await this.processJiraWebhook(userId, payload);
          break;
        case 'asana':
          await this.processAsanaWebhook(userId, payload);
          break;
        case 'github':
          await this.processGitHubWebhook(userId, payload);
          break;
        default:
          console.warn(`Webhook handler not implemented for ${provider}`);
      }

      // Log webhook activity
      await db.collection('users').doc(userId).collection('webhook_logs').add({
        provider,
        event: payload.event || payload.webhookEvent,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
        success: true
      });

    } catch (error) {
      console.error(`Webhook processing error:`, error);
      
      // Log error
      await db.collection('users').doc(userId).collection('webhook_logs').add({
        provider,
        event: payload.event || payload.webhookEvent,
        error: error.message,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
        success: false
      });

      throw error;
    }
  }

  // Private methods

  private async getOrCreateIntegrationConfig(userId: string, provider: string, credentials: any): Promise<IntegrationConfig> {
    let config = await this.getIntegrationConfig(userId, provider);
    
    if (!config) {
      // Create default config
      const defaultConfig: IntegrationConfig = {
        provider,
        apiKey: credentials.apiKey || '',
        baseUrl: this.getProviderBaseUrl(provider),
        credentials,
        settings: this.getDefaultSettings(provider),
        isEnabled: true
      };

      await this.configureIntegration(userId, provider, defaultConfig);
      config = defaultConfig;
    }

    return config;
  }

  private async getIntegrationConfig(userId: string, provider: string): Promise<IntegrationConfig | null> {
    const doc = await db.collection('users').doc(userId).collection('integrations').doc(provider).get();
    return doc.exists ? doc.data() as IntegrationConfig : null;
  }

  private async fetchExternalTasks(config: IntegrationConfig): Promise<ExternalTask[]> {
    switch (config.provider) {
      case 'jira':
        return this.fetchJiraTasks(config);
      case 'asana':
        return this.fetchAsanaTasks(config);
      case 'trello':
        return this.fetchTrelloTasks(config);
      case 'notion':
        return this.fetchNotionTasks(config);
      case 'todoist':
        return this.fetchTodoistTasks(config);
      case 'github':
        return this.fetchGitHubTasks(config);
      default:
        throw new Error(`Unsupported provider: ${config.provider}`);
    }
  }

  private async fetchJiraTasks(config: IntegrationConfig): Promise<ExternalTask[]> {
    const auth = Buffer.from(`${config.credentials.username}:${config.apiKey}`).toString('base64');
    
    const response = await axios.get(`${config.baseUrl}/rest/api/2/search`, {
      headers: {
        'Authorization': `Basic ${auth}`,
        'Accept': 'application/json'
      },
      params: {
        jql: config.settings.jql || 'assignee = currentUser() AND status != Done',
        fields: 'summary,description,status,priority,assignee,created,updated,issuetype',
        maxResults: 100
      }
    });

    return response.data.issues.map((issue: any): ExternalTask => ({
      externalId: issue.key,
      title: issue.fields.summary,
      description: issue.fields.description || '',
      status: issue.fields.status.name,
      priority: this.mapJiraPriority(issue.fields.priority?.name),
      category: this.mapJiraTypeToCategory(issue.fields.issuetype?.name),
      assignee: issue.fields.assignee?.displayName,
      url: `${config.baseUrl}/browse/${issue.key}`,
      metadata: {
        issueType: issue.fields.issuetype?.name,
        project: issue.fields.project?.name,
        created: issue.fields.created,
        updated: issue.fields.updated
      }
    }));
  }

  private async fetchAsanaTasks(config: IntegrationConfig): Promise<ExternalTask[]> {
    const response = await axios.get('https://app.asana.com/api/1.0/tasks', {
      headers: {
        'Authorization': `Bearer ${config.apiKey}`
      },
      params: {
        assignee: 'me',
        completed_since: 'now',
        opt_fields: 'name,notes,completed,priority,due_date,tags,projects'
      }
    });

    return response.data.data.map((task: any): ExternalTask => ({
      externalId: task.gid,
      title: task.name,
      description: task.notes || '',
      status: task.completed ? 'completed' : 'open',
      priority: this.mapAsanaPriority(task.priority),
      dueDate: task.due_date ? new Date(task.due_date) : undefined,
      labels: task.tags?.map((tag: any) => tag.name) || [],
      url: `https://app.asana.com/0/0/${task.gid}`,
      metadata: {
        projects: task.projects?.map((p: any) => p.name) || []
      }
    }));
  }

  private async fetchTrelloTasks(config: IntegrationConfig): Promise<ExternalTask[]> {
    const response = await axios.get('https://api.trello.com/1/members/me/cards', {
      params: {
        key: config.credentials.key,
        token: config.apiKey,
        filter: 'open',
        fields: 'name,desc,due,labels,list,board'
      }
    });

    return response.data.map((card: any): ExternalTask => ({
      externalId: card.id,
      title: card.name,
      description: card.desc || '',
      status: 'open',
      dueDate: card.due ? new Date(card.due) : undefined,
      labels: card.labels?.map((label: any) => label.name) || [],
      url: card.shortUrl,
      metadata: {
        listId: card.list?.id,
        boardId: card.board?.id
      }
    }));
  }

  private async fetchNotionTasks(config: IntegrationConfig): Promise<ExternalTask[]> {
    const response = await axios.post(`https://api.notion.com/v1/databases/${config.settings.databaseId}/query`, {
      filter: {
        property: 'Status',
        select: {
          does_not_equal: 'Done'
        }
      }
    }, {
      headers: {
        'Authorization': `Bearer ${config.apiKey}`,
        'Notion-Version': '2022-06-28'
      }
    });

    return response.data.results.map((page: any): ExternalTask => ({
      externalId: page.id,
      title: page.properties.Name?.title?.[0]?.plain_text || 'Untitled',
      description: page.properties.Description?.rich_text?.[0]?.plain_text || '',
      status: page.properties.Status?.select?.name || 'open',
      priority: page.properties.Priority?.select?.name,
      dueDate: page.properties['Due Date']?.date?.start ? new Date(page.properties['Due Date'].date.start) : undefined,
      url: page.url,
      metadata: {
        createdTime: page.created_time,
        lastEditedTime: page.last_edited_time
      }
    }));
  }

  private async fetchTodoistTasks(config: IntegrationConfig): Promise<ExternalTask[]> {
    const response = await axios.get('https://api.todoist.com/rest/v2/tasks', {
      headers: {
        'Authorization': `Bearer ${config.apiKey}`
      }
    });

    return response.data.map((task: any): ExternalTask => ({
      externalId: task.id,
      title: task.content,
      description: task.description || '',
      status: 'open',
      priority: this.mapTodoistPriority(task.priority),
      dueDate: task.due?.date ? new Date(task.due.date) : undefined,
      labels: task.labels || [],
      url: task.url,
      metadata: {
        projectId: task.project_id,
        sectionId: task.section_id
      }
    }));
  }

  private async fetchGitHubTasks(config: IntegrationConfig): Promise<ExternalTask[]> {
    const response = await axios.get(`https://api.github.com/repos/${config.settings.repository}/issues`, {
      headers: {
        'Authorization': `token ${config.apiKey}`,
        'Accept': 'application/vnd.github.v3+json'
      },
      params: {
        state: 'open',
        assignee: config.settings.username || 'assigned'
      }
    });

    return response.data.map((issue: any): ExternalTask => ({
      externalId: issue.id.toString(),
      title: issue.title,
      description: issue.body || '',
      status: issue.state,
      priority: this.mapGitHubPriority(issue.labels),
      labels: issue.labels?.map((label: any) => label.name) || [],
      url: issue.html_url,
      metadata: {
        number: issue.number,
        repository: config.settings.repository,
        author: issue.user.login
      }
    }));
  }

  private async importTasks(userId: string, externalTasks: ExternalTask[], provider: string): Promise<number> {
    let imported = 0;

    for (const externalTask of externalTasks) {
      try {
        // Check if task already exists
        const existingTaskQuery = await db.collection('users').doc(userId).collection('tasks')
          .where('metadata.externalId', '==', externalTask.externalId)
          .where('metadata.provider', '==', provider)
          .get();

        if (existingTaskQuery.empty) {
          // Create new task
          const taskData = {
            id: `${provider}_${externalTask.externalId}`,
            title: externalTask.title,
            description: externalTask.description,
            category: externalTask.category || 'general',
            priority: externalTask.priority || 'medium',
            status: this.mapExternalStatus(externalTask.status),
            dueDate: externalTask.dueDate,
            tags: externalTask.labels || [],
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            metadata: {
              provider,
              externalId: externalTask.externalId,
              externalUrl: externalTask.url,
              ...externalTask.metadata
            }
          };

          // Enhance with AI if possible
          try {
            const aiData = await aiService.processTask({
              title: taskData.title,
              description: taskData.description,
              category: taskData.category,
              priority: taskData.priority
            });
            taskData['aiData'] = aiData;
          } catch (aiError) {
            console.warn('AI processing failed for imported task:', aiError);
          }

          await db.collection('users').doc(userId).collection('tasks').add(taskData);
          imported++;
        } else {
          // Update existing task if changed
          const existingTask = existingTaskQuery.docs[0];
          const updates: any = {};
          let hasChanges = false;

          if (existingTask.data().title !== externalTask.title) {
            updates.title = externalTask.title;
            hasChanges = true;
          }
          
          if (existingTask.data().description !== externalTask.description) {
            updates.description = externalTask.description;
            hasChanges = true;
          }

          if (hasChanges) {
            updates.lastSynced = admin.firestore.FieldValue.serverTimestamp();
            await existingTask.ref.update(updates);
          }
        }
      } catch (error) {
        console.error(`Error importing task ${externalTask.externalId}:`, error);
      }
    }

    return imported;
  }

  private async exportTasks(config: IntegrationConfig, tasks: any[]): Promise<number> {
    let exported = 0;

    for (const task of tasks) {
      try {
        switch (config.provider) {
          case 'jira':
            await this.exportToJira(config, task);
            break;
          case 'asana':
            await this.exportToAsana(config, task);
            break;
          case 'trello':
            await this.exportToTrello(config, task);
            break;
          default:
            console.warn(`Export not implemented for ${config.provider}`);
            continue;
        }

        // Mark as exported
        await db.collection('tasks').doc(task.id).update({
          [`metadata.exported_${config.provider}`]: admin.firestore.FieldValue.serverTimestamp()
        });

        exported++;
      } catch (error) {
        console.error(`Error exporting task ${task.id}:`, error);
      }
    }

    return exported;
  }

  private async getUnexportedTasks(userId: string, provider: string): Promise<any[]> {
    const tasksSnapshot = await db.collection('users').doc(userId).collection('tasks')
      .where(`metadata.exported_${provider}`, '==', null)
      .where('metadata.provider', '!=', provider) // Don't export tasks that originated from this provider
      .limit(20) // Limit to prevent overwhelming external APIs
      .get();

    return tasksSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  }

  private async testConnection(config: IntegrationConfig): Promise<void> {
    // Test connection based on provider
    switch (config.provider) {
      case 'jira':
        await this.testJiraConnection(config);
        break;
      case 'asana':
        await this.testAsanaConnection(config);
        break;
      default:
        throw new Error(`Connection test not implemented for ${config.provider}`);
    }
  }

  private async testJiraConnection(config: IntegrationConfig): Promise<void> {
    const auth = Buffer.from(`${config.credentials.username}:${config.apiKey}`).toString('base64');
    
    await axios.get(`${config.baseUrl}/rest/api/2/myself`, {
      headers: {
        'Authorization': `Basic ${auth}`,
        'Accept': 'application/json'
      }
    });
  }

  private async testAsanaConnection(config: IntegrationConfig): Promise<void> {
    await axios.get('https://app.asana.com/api/1.0/users/me', {
      headers: {
        'Authorization': `Bearer ${config.apiKey}`
      }
    });
  }

  // Helper methods for mapping between different platforms

  private mapJiraPriority(priority: string): string {
    switch (priority?.toLowerCase()) {
      case 'highest':
      case 'blocker': return 'critical';
      case 'high': return 'high';
      case 'medium': return 'medium';
      case 'low':
      case 'lowest': return 'low';
      default: return 'medium';
    }
  }

  private mapJiraTypeToCategory(type: string): string {
    switch (type?.toLowerCase()) {
      case 'bug': return 'testing';
      case 'story':
      case 'task': return 'coding';
      case 'epic': return 'planning';
      default: return 'general';
    }
  }

  private mapAsanaPriority(priority: string): string {
    // Asana uses different priority system
    return 'medium';
  }

  private mapTodoistPriority(priority: number): string {
    switch (priority) {
      case 4: return 'critical';
      case 3: return 'high';
      case 2: return 'medium';
      case 1: return 'low';
      default: return 'medium';
    }
  }

  private mapGitHubPriority(labels: any[]): string {
    const priorityLabels = labels?.filter(label => 
      label.name.toLowerCase().includes('priority') || 
      label.name.toLowerCase().includes('urgent')
    );
    
    if (priorityLabels?.length > 0) {
      const label = priorityLabels[0].name.toLowerCase();
      if (label.includes('high') || label.includes('urgent')) return 'high';
      if (label.includes('low')) return 'low';
    }
    
    return 'medium';
  }

  private mapExternalStatus(status: string): string {
    switch (status?.toLowerCase()) {
      case 'done':
      case 'completed':
      case 'closed':
      case 'resolved': return 'completed';
      case 'in progress':
      case 'in-progress':
      case 'doing': return 'in_progress';
      default: return 'todo';
    }
  }

  private getProviderBaseUrl(provider: string): string {
    switch (provider) {
      case 'jira': return 'https://your-domain.atlassian.net';
      case 'asana': return 'https://app.asana.com/api/1.0';
      case 'trello': return 'https://api.trello.com/1';
      case 'notion': return 'https://api.notion.com/v1';
      case 'todoist': return 'https://api.todoist.com/rest/v2';
      case 'github': return 'https://api.github.com';
      default: return '';
    }
  }

  private getDefaultSettings(provider: string): Record<string, any> {
    switch (provider) {
      case 'jira':
        return {
          jql: 'assignee = currentUser() AND status != Done',
          includeSubtasks: false
        };
      case 'asana':
        return {
          workspace: null,
          includeCompleted: false
        };
      case 'github':
        return {
          repository: '',
          includeAssigned: true,
          includeMentioned: false
        };
      default:
        return {};
    }
  }

  // Webhook implementation methods (simplified)

  private async setupJiraWebhook(config: IntegrationConfig, webhookUrl: string, events: string[]): Promise<string> {
    // Implementation would create Jira webhook
    return 'webhook_id';
  }

  private async setupAsanaWebhook(config: IntegrationConfig, webhookUrl: string, events: string[]): Promise<string> {
    // Implementation would create Asana webhook
    return 'webhook_id';
  }

  private async setupGitHubWebhook(config: IntegrationConfig, webhookUrl: string, events: string[]): Promise<string> {
    // Implementation would create GitHub webhook
    return 'webhook_id';
  }

  private verifyWebhookSignature(provider: string, payload: any): boolean {
    // Implementation would verify webhook signature
    return true;
  }

  private async processJiraWebhook(userId: string, payload: any): Promise<void> {
    // Process Jira webhook payload
  }

  private async processAsanaWebhook(userId: string, payload: any): Promise<void> {
    // Process Asana webhook payload
  }

  private async processGitHubWebhook(userId: string, payload: any): Promise<void> {
    // Process GitHub webhook payload
  }

  private async exportToJira(config: IntegrationConfig, task: any): Promise<void> {
    // Export task to Jira
  }

  private async exportToAsana(config: IntegrationConfig, task: any): Promise<void> {
    // Export task to Asana
  }

  private async exportToTrello(config: IntegrationConfig, task: any): Promise<void> {
    // Export task to Trello
  }

  private async updateSyncStatus(userId: string, provider: string, status: any): Promise<void> {
    await db.collection('users').doc(userId).collection('integrations').doc(provider).update({
      lastSyncStatus: status,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    });
  }
}

export const integrationService = new IntegrationService();