"use strict";
/**
 * Integration Service for Focus Flow Timer
 * Handles third-party integrations with task management platforms
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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.integrationService = exports.IntegrationService = void 0;
const admin = __importStar(require("firebase-admin"));
const axios_1 = __importDefault(require("axios"));
const db = admin.firestore();
class IntegrationService {
    /**
     * Sync tasks with external provider
     */
    async syncTasks(userId, provider, credentials, bidirectional = true) {
        try {
            console.log(`Starting sync with ${provider} for user ${userId}`);
            const config = await this.getOrCreateIntegrationConfig(userId, provider, credentials);
            let tasksImported = 0;
            let tasksExported = 0;
            const errors = [];
            // Import tasks from external provider
            try {
                const externalTasks = await this.fetchExternalTasks(config);
                tasksImported = await this.importTasks(userId, externalTasks, provider);
            }
            catch (error) {
                console.error(`Import error for ${provider}:`, error);
                errors.push(`Import failed: ${error.message}`);
            }
            // Export tasks to external provider (if bidirectional)
            if (bidirectional) {
                try {
                    const localTasks = await this.getUnexportedTasks(userId, provider);
                    tasksExported = await this.exportTasks(config, localTasks);
                }
                catch (error) {
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
            const result = {
                success: errors.length === 0,
                message: errors.length === 0 ? 'Sync completed successfully' : 'Sync completed with errors',
                tasksImported,
                tasksExported,
                errors,
                timestamp: new Date()
            };
            console.log(`Sync completed for ${provider}: imported ${tasksImported}, exported ${tasksExported}`);
            return result;
        }
        catch (error) {
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
    async configureIntegration(userId, provider, config) {
        const integrationRef = db.collection('users').doc(userId).collection('integrations').doc(provider);
        await integrationRef.set(Object.assign(Object.assign({}, config), { provider, configuredAt: admin.firestore.FieldValue.serverTimestamp(), lastUpdated: admin.firestore.FieldValue.serverTimestamp() }), { merge: true });
        // Test the connection
        try {
            await this.testConnection(Object.assign({ provider }, config));
            await integrationRef.update({ connectionStatus: 'active', lastTested: admin.firestore.FieldValue.serverTimestamp() });
        }
        catch (error) {
            await integrationRef.update({ connectionStatus: 'failed', lastError: error.message });
            throw error;
        }
    }
    /**
     * Get available integrations
     */
    getAvailableIntegrations() {
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
    async setupWebhook(userId, provider, events) {
        const webhookUrl = `https://your-cloud-function-url/webhooks/${provider}/${userId}`;
        const config = await this.getIntegrationConfig(userId, provider);
        if (!config) {
            throw new Error(`Integration not configured for ${provider}`);
        }
        let webhookId;
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
    async handleWebhook(provider, userId, payload) {
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
        }
        catch (error) {
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
    async getOrCreateIntegrationConfig(userId, provider, credentials) {
        let config = await this.getIntegrationConfig(userId, provider);
        if (!config) {
            // Create default config
            const defaultConfig = {
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
    async getIntegrationConfig(userId, provider) {
        const doc = await db.collection('users').doc(userId).collection('integrations').doc(provider).get();
        return doc.exists ? doc.data() : null;
    }
    async fetchExternalTasks(config) {
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
    async fetchJiraTasks(config) {
        const auth = Buffer.from(`${config.credentials.username}:${config.apiKey}`).toString('base64');
        const response = await axios_1.default.get(`${config.baseUrl}/rest/api/2/search`, {
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
        return response.data.issues.map((issue) => {
            var _a, _b, _c, _d, _e;
            return ({
                externalId: issue.key,
                title: issue.fields.summary,
                description: issue.fields.description || '',
                status: issue.fields.status.name,
                priority: this.mapJiraPriority((_a = issue.fields.priority) === null || _a === void 0 ? void 0 : _a.name),
                category: this.mapJiraTypeToCategory((_b = issue.fields.issuetype) === null || _b === void 0 ? void 0 : _b.name),
                assignee: (_c = issue.fields.assignee) === null || _c === void 0 ? void 0 : _c.displayName,
                url: `${config.baseUrl}/browse/${issue.key}`,
                metadata: {
                    issueType: (_d = issue.fields.issuetype) === null || _d === void 0 ? void 0 : _d.name,
                    project: (_e = issue.fields.project) === null || _e === void 0 ? void 0 : _e.name,
                    created: issue.fields.created,
                    updated: issue.fields.updated
                }
            });
        });
    }
    async fetchAsanaTasks(config) {
        const response = await axios_1.default.get('https://app.asana.com/api/1.0/tasks', {
            headers: {
                'Authorization': `Bearer ${config.apiKey}`
            },
            params: {
                assignee: 'me',
                completed_since: 'now',
                opt_fields: 'name,notes,completed,priority,due_date,tags,projects'
            }
        });
        return response.data.data.map((task) => {
            var _a, _b;
            return ({
                externalId: task.gid,
                title: task.name,
                description: task.notes || '',
                status: task.completed ? 'completed' : 'open',
                priority: this.mapAsanaPriority(task.priority),
                dueDate: task.due_date ? new Date(task.due_date) : undefined,
                labels: ((_a = task.tags) === null || _a === void 0 ? void 0 : _a.map((tag) => tag.name)) || [],
                url: `https://app.asana.com/0/0/${task.gid}`,
                metadata: {
                    projects: ((_b = task.projects) === null || _b === void 0 ? void 0 : _b.map((p) => p.name)) || []
                }
            });
        });
    }
    async fetchTrelloTasks(config) {
        const response = await axios_1.default.get('https://api.trello.com/1/members/me/cards', {
            params: {
                key: config.credentials.key,
                token: config.apiKey,
                filter: 'open',
                fields: 'name,desc,due,labels,list,board'
            }
        });
        return response.data.map((card) => {
            var _a, _b, _c;
            return ({
                externalId: card.id,
                title: card.name,
                description: card.desc || '',
                status: 'open',
                dueDate: card.due ? new Date(card.due) : undefined,
                labels: ((_a = card.labels) === null || _a === void 0 ? void 0 : _a.map((label) => label.name)) || [],
                url: card.shortUrl,
                metadata: {
                    listId: (_b = card.list) === null || _b === void 0 ? void 0 : _b.id,
                    boardId: (_c = card.board) === null || _c === void 0 ? void 0 : _c.id
                }
            });
        });
    }
    async fetchNotionTasks(config) {
        const response = await axios_1.default.post(`https://api.notion.com/v1/databases/${config.settings.databaseId}/query`, {
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
        return response.data.results.map((page) => {
            var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l, _m;
            return ({
                externalId: page.id,
                title: ((_c = (_b = (_a = page.properties.Name) === null || _a === void 0 ? void 0 : _a.title) === null || _b === void 0 ? void 0 : _b[0]) === null || _c === void 0 ? void 0 : _c.plain_text) || 'Untitled',
                description: ((_f = (_e = (_d = page.properties.Description) === null || _d === void 0 ? void 0 : _d.rich_text) === null || _e === void 0 ? void 0 : _e[0]) === null || _f === void 0 ? void 0 : _f.plain_text) || '',
                status: ((_h = (_g = page.properties.Status) === null || _g === void 0 ? void 0 : _g.select) === null || _h === void 0 ? void 0 : _h.name) || 'open',
                priority: (_k = (_j = page.properties.Priority) === null || _j === void 0 ? void 0 : _j.select) === null || _k === void 0 ? void 0 : _k.name,
                dueDate: ((_m = (_l = page.properties['Due Date']) === null || _l === void 0 ? void 0 : _l.date) === null || _m === void 0 ? void 0 : _m.start) ? new Date(page.properties['Due Date'].date.start) : undefined,
                url: page.url,
                metadata: {
                    createdTime: page.created_time,
                    lastEditedTime: page.last_edited_time
                }
            });
        });
    }
    async fetchTodoistTasks(config) {
        const response = await axios_1.default.get('https://api.todoist.com/rest/v2/tasks', {
            headers: {
                'Authorization': `Bearer ${config.apiKey}`
            }
        });
        return response.data.map((task) => {
            var _a;
            return ({
                externalId: task.id,
                title: task.content,
                description: task.description || '',
                status: 'open',
                priority: this.mapTodoistPriority(task.priority),
                dueDate: ((_a = task.due) === null || _a === void 0 ? void 0 : _a.date) ? new Date(task.due.date) : undefined,
                labels: task.labels || [],
                url: task.url,
                metadata: {
                    projectId: task.project_id,
                    sectionId: task.section_id
                }
            });
        });
    }
    async fetchGitHubTasks(config) {
        const response = await axios_1.default.get(`https://api.github.com/repos/${config.settings.repository}/issues`, {
            headers: {
                'Authorization': `token ${config.apiKey}`,
                'Accept': 'application/vnd.github.v3+json'
            },
            params: {
                state: 'open',
                assignee: config.settings.username || 'assigned'
            }
        });
        return response.data.map((issue) => {
            var _a;
            return ({
                externalId: issue.id.toString(),
                title: issue.title,
                description: issue.body || '',
                status: issue.state,
                priority: this.mapGitHubPriority(issue.labels),
                labels: ((_a = issue.labels) === null || _a === void 0 ? void 0 : _a.map((label) => label.name)) || [],
                url: issue.html_url,
                metadata: {
                    number: issue.number,
                    repository: config.settings.repository,
                    author: issue.user.login
                }
            });
        });
    }
    async importTasks(userId, externalTasks, provider) {
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
                        metadata: Object.assign({ provider, externalId: externalTask.externalId, externalUrl: externalTask.url }, externalTask.metadata)
                    };
                    // Note: AI processing removed to use free resources only
                    await db.collection('users').doc(userId).collection('tasks').add(taskData);
                    imported++;
                }
                else {
                    // Update existing task if changed
                    const existingTask = existingTaskQuery.docs[0];
                    const updates = {};
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
            }
            catch (error) {
                console.error(`Error importing task ${externalTask.externalId}:`, error);
            }
        }
        return imported;
    }
    async exportTasks(config, tasks) {
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
            }
            catch (error) {
                console.error(`Error exporting task ${task.id}:`, error);
            }
        }
        return exported;
    }
    async getUnexportedTasks(userId, provider) {
        const tasksSnapshot = await db.collection('users').doc(userId).collection('tasks')
            .where(`metadata.exported_${provider}`, '==', null)
            .where('metadata.provider', '!=', provider) // Don't export tasks that originated from this provider
            .limit(20) // Limit to prevent overwhelming external APIs
            .get();
        return tasksSnapshot.docs.map(doc => (Object.assign({ id: doc.id }, doc.data())));
    }
    async testConnection(config) {
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
    async testJiraConnection(config) {
        const auth = Buffer.from(`${config.credentials.username}:${config.apiKey}`).toString('base64');
        await axios_1.default.get(`${config.baseUrl}/rest/api/2/myself`, {
            headers: {
                'Authorization': `Basic ${auth}`,
                'Accept': 'application/json'
            }
        });
    }
    async testAsanaConnection(config) {
        await axios_1.default.get('https://app.asana.com/api/1.0/users/me', {
            headers: {
                'Authorization': `Bearer ${config.apiKey}`
            }
        });
    }
    // Helper methods for mapping between different platforms
    mapJiraPriority(priority) {
        switch (priority === null || priority === void 0 ? void 0 : priority.toLowerCase()) {
            case 'highest':
            case 'blocker': return 'critical';
            case 'high': return 'high';
            case 'medium': return 'medium';
            case 'low':
            case 'lowest': return 'low';
            default: return 'medium';
        }
    }
    mapJiraTypeToCategory(type) {
        switch (type === null || type === void 0 ? void 0 : type.toLowerCase()) {
            case 'bug': return 'testing';
            case 'story':
            case 'task': return 'coding';
            case 'epic': return 'planning';
            default: return 'general';
        }
    }
    mapAsanaPriority(priority) {
        // Asana uses different priority system
        return 'medium';
    }
    mapTodoistPriority(priority) {
        switch (priority) {
            case 4: return 'critical';
            case 3: return 'high';
            case 2: return 'medium';
            case 1: return 'low';
            default: return 'medium';
        }
    }
    mapGitHubPriority(labels) {
        const priorityLabels = labels === null || labels === void 0 ? void 0 : labels.filter(label => label.name.toLowerCase().includes('priority') ||
            label.name.toLowerCase().includes('urgent'));
        if ((priorityLabels === null || priorityLabels === void 0 ? void 0 : priorityLabels.length) > 0) {
            const label = priorityLabels[0].name.toLowerCase();
            if (label.includes('high') || label.includes('urgent'))
                return 'high';
            if (label.includes('low'))
                return 'low';
        }
        return 'medium';
    }
    mapExternalStatus(status) {
        switch (status === null || status === void 0 ? void 0 : status.toLowerCase()) {
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
    getProviderBaseUrl(provider) {
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
    getDefaultSettings(provider) {
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
    async setupJiraWebhook(config, webhookUrl, events) {
        // Implementation would create Jira webhook
        return 'webhook_id';
    }
    async setupAsanaWebhook(config, webhookUrl, events) {
        // Implementation would create Asana webhook
        return 'webhook_id';
    }
    async setupGitHubWebhook(config, webhookUrl, events) {
        // Implementation would create GitHub webhook
        return 'webhook_id';
    }
    verifyWebhookSignature(provider, payload) {
        // Implementation would verify webhook signature
        return true;
    }
    async processJiraWebhook(userId, payload) {
        // Process Jira webhook payload
    }
    async processAsanaWebhook(userId, payload) {
        // Process Asana webhook payload
    }
    async processGitHubWebhook(userId, payload) {
        // Process GitHub webhook payload
    }
    async exportToJira(config, task) {
        // Export task to Jira
    }
    async exportToAsana(config, task) {
        // Export task to Asana
    }
    async exportToTrello(config, task) {
        // Export task to Trello
    }
    async updateSyncStatus(userId, provider, status) {
        await db.collection('users').doc(userId).collection('integrations').doc(provider).update({
            lastSyncStatus: status,
            lastUpdated: admin.firestore.FieldValue.serverTimestamp()
        });
    }
}
exports.IntegrationService = IntegrationService;
exports.integrationService = new IntegrationService();
//# sourceMappingURL=integrationService.js.map