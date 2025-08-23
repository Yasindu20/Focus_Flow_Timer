/**
 * Security Service for Focus Flow Timer
 * Handles authentication, authorization, rate limiting, and security validation
 */

import * as admin from 'firebase-admin';
import * as crypto from 'crypto';

const db = admin.firestore();
const auth = admin.auth();

export interface UserPermissions {
  userId: string;
  role: 'user' | 'premium' | 'admin' | 'enterprise';
  permissions: string[];
  features: string[];
  limits: {
    maxTasks: number;
    maxProjects: number;
    maxIntegrations: number;
    maxExports: number;
    aiRequestsPerDay: number;
    storageLimit: number; // in MB
  };
  subscription: {
    plan: string;
    status: 'active' | 'cancelled' | 'expired' | 'trial';
    expiresAt?: Date;
    features: string[];
  };
}

export interface SecurityLog {
  userId: string;
  action: string;
  resource: string;
  timestamp: Date;
  ip?: string;
  userAgent?: string;
  success: boolean;
  details?: Record<string, any>;
}

export interface RateLimit {
  key: string;
  limit: number;
  windowMs: number;
  current: number;
  resetTime: Date;
}

export class SecurityService {
  private rateLimitCache = new Map<string, RateLimit>();

  /**
   * Validate user permissions for a specific resource and action
   */
  async validatePermission(userId: string, resource: string, action: string): Promise<boolean> {
    try {
      const userPermissions = await this.getUserPermissions(userId);
      const requiredPermission = `${resource}:${action}`;

      // Check if user has specific permission
      if (userPermissions.permissions.includes(requiredPermission)) {
        await this.logSecurityEvent(userId, action, resource, true);
        return true;
      }

      // Check if user has wildcard permission for resource
      if (userPermissions.permissions.includes(`${resource}:*`)) {
        await this.logSecurityEvent(userId, action, resource, true);
        return true;
      }

      // Check if user has admin role
      if (userPermissions.role === 'admin') {
        await this.logSecurityEvent(userId, action, resource, true);
        return true;
      }

      await this.logSecurityEvent(userId, action, resource, false);
      return false;

    } catch (error) {
      console.error('Permission validation error:', error);
      await this.logSecurityEvent(userId, action, resource, false, { error: error.message });
      return false;
    }
  }

  /**
   * Check if user has access to a specific feature
   */
  async hasFeatureAccess(userId: string, feature: string): Promise<boolean> {
    try {
      const userPermissions = await this.getUserPermissions(userId);
      return userPermissions.features.includes(feature) || userPermissions.role === 'admin';
    } catch (error) {
      console.error('Feature access check error:', error);
      return false;
    }
  }

  /**
   * Validate rate limits for API endpoints
   */
  async checkRateLimit(key: string, limit: number = 100, windowMs: number = 60000): Promise<{
    allowed: boolean;
    remaining: number;
    resetTime: Date;
  }> {
    const now = new Date();
    const rateLimitKey = `rate_limit_${key}`;
    
    let rateLimit = this.rateLimitCache.get(rateLimitKey);

    // Initialize or reset if window expired
    if (!rateLimit || now > rateLimit.resetTime) {
      rateLimit = {
        key,
        limit,
        windowMs,
        current: 0,
        resetTime: new Date(now.getTime() + windowMs)
      };
    }

    rateLimit.current += 1;
    this.rateLimitCache.set(rateLimitKey, rateLimit);

    const allowed = rateLimit.current <= limit;
    const remaining = Math.max(0, limit - rateLimit.current);

    // Store in database for distributed rate limiting
    if (!allowed) {
      await this.logRateLimitViolation(key, rateLimit);
    }

    return {
      allowed,
      remaining,
      resetTime: rateLimit.resetTime
    };
  }

  /**
   * Validate usage limits for premium features
   */
  async checkUsageLimit(userId: string, resource: string): Promise<{
    allowed: boolean;
    current: number;
    limit: number;
    resetPeriod: 'daily' | 'monthly' | 'unlimited';
  }> {
    try {
      const userPermissions = await this.getUserPermissions(userId);
      const currentUsage = await this.getCurrentUsage(userId, resource);
      
      let limit: number;
      let resetPeriod: 'daily' | 'monthly' | 'unlimited' = 'monthly';

      switch (resource) {
        case 'tasks':
          limit = userPermissions.limits.maxTasks;
          break;
        case 'projects':
          limit = userPermissions.limits.maxProjects;
          break;
        case 'integrations':
          limit = userPermissions.limits.maxIntegrations;
          break;
        case 'exports':
          limit = userPermissions.limits.maxExports;
          resetPeriod = 'monthly';
          break;
        case 'ai_requests':
          limit = userPermissions.limits.aiRequestsPerDay;
          resetPeriod = 'daily';
          break;
        default:
          limit = 0;
      }

      const allowed = currentUsage < limit || limit === -1; // -1 means unlimited

      return {
        allowed,
        current: currentUsage,
        limit,
        resetPeriod
      };

    } catch (error) {
      console.error('Usage limit check error:', error);
      return {
        allowed: false,
        current: 0,
        limit: 0,
        resetPeriod: 'monthly'
      };
    }
  }

  /**
   * Sanitize and validate input data
   */
  sanitizeInput(data: any, schema: Record<string, any>): any {
    const sanitized: any = {};

    for (const [key, rules] of Object.entries(schema)) {
      const value = data[key];

      if (rules.required && (value === undefined || value === null)) {
        throw new Error(`Required field missing: ${key}`);
      }

      if (value === undefined || value === null) {
        continue;
      }

      // Type validation
      if (rules.type) {
        if (typeof value !== rules.type) {
          throw new Error(`Invalid type for ${key}: expected ${rules.type}, got ${typeof value}`);
        }
      }

      // String sanitization
      if (typeof value === 'string') {
        let sanitizedValue = value;

        // Remove HTML tags
        if (rules.stripHtml) {
          sanitizedValue = sanitizedValue.replace(/<[^>]*>/g, '');
        }

        // Trim whitespace
        if (rules.trim !== false) {
          sanitizedValue = sanitizedValue.trim();
        }

        // Length validation
        if (rules.maxLength && sanitizedValue.length > rules.maxLength) {
          throw new Error(`${key} exceeds maximum length of ${rules.maxLength}`);
        }

        if (rules.minLength && sanitizedValue.length < rules.minLength) {
          throw new Error(`${key} is below minimum length of ${rules.minLength}`);
        }

        // Pattern validation
        if (rules.pattern && !new RegExp(rules.pattern).test(sanitizedValue)) {
          throw new Error(`${key} does not match required pattern`);
        }

        sanitized[key] = sanitizedValue;
      }
      // Number validation
      else if (typeof value === 'number') {
        if (rules.min !== undefined && value < rules.min) {
          throw new Error(`${key} is below minimum value of ${rules.min}`);
        }

        if (rules.max !== undefined && value > rules.max) {
          throw new Error(`${key} exceeds maximum value of ${rules.max}`);
        }

        sanitized[key] = value;
      }
      // Array validation
      else if (Array.isArray(value)) {
        if (rules.maxItems && value.length > rules.maxItems) {
          throw new Error(`${key} exceeds maximum items of ${rules.maxItems}`);
        }

        sanitized[key] = value;
      }
      else {
        sanitized[key] = value;
      }
    }

    return sanitized;
  }

  /**
   * Generate secure API key
   */
  generateApiKey(userId: string, purpose: string): string {
    const timestamp = Date.now();
    const randomBytes = crypto.randomBytes(16).toString('hex');
    const payload = `${userId}:${purpose}:${timestamp}`;
    const signature = crypto.createHmac('sha256', process.env.API_KEY_SECRET || 'secret')
      .update(payload)
      .digest('hex');
    
    return `ffk_${Buffer.from(`${payload}:${signature}`).toString('base64')}`;
  }

  /**
   * Validate API key
   */
  validateApiKey(apiKey: string): { valid: boolean; userId?: string; purpose?: string } {
    try {
      if (!apiKey.startsWith('ffk_')) {
        return { valid: false };
      }

      const payload = Buffer.from(apiKey.slice(4), 'base64').toString();
      const [userId, purpose, timestamp, signature] = payload.split(':');
      
      const expectedPayload = `${userId}:${purpose}:${timestamp}`;
      const expectedSignature = crypto.createHmac('sha256', process.env.API_KEY_SECRET || 'secret')
        .update(expectedPayload)
        .digest('hex');
      
      if (signature !== expectedSignature) {
        return { valid: false };
      }

      // Check if key is not too old (optional expiration)
      const keyAge = Date.now() - parseInt(timestamp);
      const maxAge = 365 * 24 * 60 * 60 * 1000; // 1 year
      
      if (keyAge > maxAge) {
        return { valid: false };
      }

      return { valid: true, userId, purpose };

    } catch (error) {
      return { valid: false };
    }
  }

  /**
   * Encrypt sensitive data
   */
  encryptData(data: string, userId: string): string {
    const algorithm = 'aes-256-gcm';
    const key = crypto.scryptSync(process.env.ENCRYPTION_KEY || 'key', userId, 32);
    const iv = crypto.randomBytes(16);
    
    const cipher = crypto.createCipher(algorithm, key);
    cipher.setAAD(Buffer.from(userId));
    
    let encrypted = cipher.update(data, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    
    const tag = cipher.getAuthTag();
    
    return `${iv.toString('hex')}:${tag.toString('hex')}:${encrypted}`;
  }

  /**
   * Decrypt sensitive data
   */
  decryptData(encryptedData: string, userId: string): string {
    const algorithm = 'aes-256-gcm';
    const key = crypto.scryptSync(process.env.ENCRYPTION_KEY || 'key', userId, 32);
    
    const [ivHex, tagHex, encrypted] = encryptedData.split(':');
    const iv = Buffer.from(ivHex, 'hex');
    const tag = Buffer.from(tagHex, 'hex');
    
    const decipher = crypto.createDecipher(algorithm, key);
    decipher.setAAD(Buffer.from(userId));
    decipher.setAuthTag(tag);
    
    let decrypted = decipher.update(encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    
    return decrypted;
  }

  /**
   * Audit user actions
   */
  async auditUserAction(userId: string, action: string, resource: string, details?: any): Promise<void> {
    try {
      await db.collection('security_audit').add({
        userId,
        action,
        resource,
        details: details || {},
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        ip: details?.ip,
        userAgent: details?.userAgent
      });
    } catch (error) {
      console.error('Audit logging error:', error);
    }
  }

  /**
   * Get security logs for a user
   */
  async getSecurityLogs(userId: string, limit: number = 50): Promise<SecurityLog[]> {
    try {
      const logsSnapshot = await db.collection('security_logs')
        .where('userId', '==', userId)
        .orderBy('timestamp', 'desc')
        .limit(limit)
        .get();

      return logsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as SecurityLog[];

    } catch (error) {
      console.error('Get security logs error:', error);
      return [];
    }
  }

  /**
   * Block suspicious user activity
   */
  async blockUser(userId: string, reason: string, duration?: number): Promise<void> {
    try {
      const blockData: any = {
        userId,
        reason,
        blockedAt: admin.firestore.FieldValue.serverTimestamp(),
        blockedBy: 'system',
        active: true
      };

      if (duration) {
        blockData.expiresAt = new Date(Date.now() + duration);
      }

      await db.collection('user_blocks').add(blockData);

      // Disable user account in Firebase Auth
      await auth.updateUser(userId, { disabled: true });

      await this.logSecurityEvent(userId, 'user_blocked', 'account', true, { reason, duration });

    } catch (error) {
      console.error('Block user error:', error);
      throw error;
    }
  }

  /**
   * Check if user is blocked
   */
  async isUserBlocked(userId: string): Promise<{ blocked: boolean; reason?: string; expiresAt?: Date }> {
    try {
      const blockSnapshot = await db.collection('user_blocks')
        .where('userId', '==', userId)
        .where('active', '==', true)
        .limit(1)
        .get();

      if (blockSnapshot.empty) {
        return { blocked: false };
      }

      const blockData = blockSnapshot.docs[0].data();
      
      // Check if block has expired
      if (blockData.expiresAt && blockData.expiresAt.toDate() < new Date()) {
        await blockSnapshot.docs[0].ref.update({ active: false });
        return { blocked: false };
      }

      return {
        blocked: true,
        reason: blockData.reason,
        expiresAt: blockData.expiresAt?.toDate()
      };

    } catch (error) {
      console.error('Check user blocked error:', error);
      return { blocked: false };
    }
  }

  // Private helper methods

  private async getUserPermissions(userId: string): Promise<UserPermissions> {
    const userDoc = await db.collection('users').doc(userId).get();
    const userData = userDoc.data();

    if (!userData) {
      throw new Error('User not found');
    }

    // Default permissions for regular users
    let permissions: UserPermissions = {
      userId,
      role: userData.role || 'user',
      permissions: [
        'tasks:read',
        'tasks:create',
        'tasks:update',
        'tasks:delete',
        'sessions:read',
        'sessions:create',
        'analytics:read'
      ],
      features: [
        'basic_timer',
        'task_management',
        'basic_analytics'
      ],
      limits: {
        maxTasks: 100,
        maxProjects: 3,
        maxIntegrations: 1,
        maxExports: 2,
        aiRequestsPerDay: 10,
        storageLimit: 100
      },
      subscription: {
        plan: 'free',
        status: 'active',
        features: ['basic_timer', 'task_management']
      }
    };

    // Enhanced permissions for premium users
    if (userData.role === 'premium') {
      permissions.permissions.push(
        'integrations:read',
        'integrations:create',
        'exports:create',
        'ai:access'
      );
      permissions.features.push(
        'advanced_analytics',
        'integrations',
        'ai_features',
        'export_data',
        'priority_support'
      );
      permissions.limits = {
        maxTasks: 1000,
        maxProjects: 20,
        maxIntegrations: 5,
        maxExports: 20,
        aiRequestsPerDay: 100,
        storageLimit: 1000
      };
    }

    // Enterprise permissions
    if (userData.role === 'enterprise') {
      permissions.permissions.push(
        'team:manage',
        'admin:read',
        'webhooks:create',
        'api:access'
      );
      permissions.features.push(
        'team_management',
        'advanced_integrations',
        'custom_reporting',
        'webhook_support',
        'api_access',
        'priority_support'
      );
      permissions.limits = {
        maxTasks: -1, // unlimited
        maxProjects: -1,
        maxIntegrations: -1,
        maxExports: -1,
        aiRequestsPerDay: 1000,
        storageLimit: 10000
      };
    }

    // Admin permissions (full access)
    if (userData.role === 'admin') {
      permissions.permissions = ['*:*']; // Wildcard permission
      permissions.features.push('admin_panel', 'system_management');
      permissions.limits = {
        maxTasks: -1,
        maxProjects: -1,
        maxIntegrations: -1,
        maxExports: -1,
        aiRequestsPerDay: -1,
        storageLimit: -1
      };
    }

    return permissions;
  }

  private async getCurrentUsage(userId: string, resource: string): Promise<number> {
    try {
      const now = new Date();
      let query: admin.firestore.Query;

      switch (resource) {
        case 'tasks':
          const tasksSnapshot = await db.collection('users').doc(userId).collection('tasks')
            .where('createdAt', '>=', new Date(now.getFullYear(), now.getMonth(), 1))
            .get();
          return tasksSnapshot.size;

        case 'projects':
          const projectsSnapshot = await db.collection('users').doc(userId).collection('projects').get();
          return projectsSnapshot.size;

        case 'integrations':
          const integrationsSnapshot = await db.collection('users').doc(userId).collection('integrations')
            .where('isEnabled', '==', true)
            .get();
          return integrationsSnapshot.size;

        case 'exports':
          const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
          const exportsSnapshot = await db.collection('users').doc(userId).collection('exports')
            .where('createdAt', '>=', startOfMonth)
            .get();
          return exportsSnapshot.size;

        case 'ai_requests':
          const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
          const aiRequestsSnapshot = await db.collection('users').doc(userId).collection('ai_requests')
            .where('timestamp', '>=', startOfDay)
            .get();
          return aiRequestsSnapshot.size;

        default:
          return 0;
      }
    } catch (error) {
      console.error('Get current usage error:', error);
      return 0;
    }
  }

  private async logSecurityEvent(
    userId: string,
    action: string,
    resource: string,
    success: boolean,
    details?: any
  ): Promise<void> {
    try {
      await db.collection('security_logs').add({
        userId,
        action,
        resource,
        success,
        details: details || {},
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });
    } catch (error) {
      console.error('Security logging error:', error);
    }
  }

  private async logRateLimitViolation(key: string, rateLimit: RateLimit): Promise<void> {
    try {
      await db.collection('rate_limit_violations').add({
        key,
        limit: rateLimit.limit,
        current: rateLimit.current,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });
    } catch (error) {
      console.error('Rate limit logging error:', error);
    }
  }
}

export const securityService = new SecurityService();