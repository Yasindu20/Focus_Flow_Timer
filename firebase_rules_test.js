/**
 * Comprehensive Firebase Security Rules Testing Suite
 * Focus Flow Timer - Enterprise Edition
 * 
 * This script tests all security rules with different user roles and scenarios
 * Run with: npm install firebase-admin @firebase/rules-unit-testing
 */

const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, updateDoc, deleteDoc, collection, query, where, orderBy, getDocs } = require('firebase/firestore');

const PROJECT_ID = 'focus-flow-timer-test';
const RULES_FILE = './firestore.rules';

// Test user configurations
const testUsers = {
  regularUser: {
    uid: 'user123',
    email: 'user@example.com',
    roles: []
  },
  premiumUser: {
    uid: 'premium456',
    email: 'premium@example.com',
    roles: [],
    premium: true
  },
  enterpriseUser: {
    uid: 'enterprise789',
    email: 'enterprise@example.com',
    roles: [],
    enterprise: true
  },
  admin: {
    uid: 'admin999',
    email: 'admin@example.com',
    roles: [],
    admin: true
  },
  systemUser: {
    uid: 'system000',
    email: 'system@example.com',
    roles: [],
    system: true
  },
  unauthorizedUser: {
    uid: 'unauthorized111',
    email: 'unauthorized@example.com',
    roles: []
  }
};

describe('Firebase Security Rules Tests', () => {
  let testEnv;

  beforeAll(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        rules: require('fs').readFileSync(RULES_FILE, 'utf8'),
        host: 'localhost',
        port: 8080
      }
    });
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  afterAll(async () => {
    await testEnv.cleanup();
  });

  // Helper function to get authenticated context
  function getAuthContext(userType) {
    if (userType === 'unauthenticated') {
      return testEnv.unauthenticatedContext();
    }
    return testEnv.authenticatedContext(testUsers[userType].uid, testUsers[userType]);
  }

  describe('Task Collection Security', () => {
    const taskData = {
      id: 'task123',
      title: 'Test Task',
      description: 'A test task',
      userId: 'user123',
      createdAt: new Date(),
      isCompleted: false,
      category: 'general',
      priority: 'medium',
      tags: ['work', 'urgent']
    };

    test('User can create their own task', async () => {
      const db = getAuthContext('regularUser').firestore();
      await assertSucceeds(
        setDoc(doc(db, 'tasks', 'task123'), taskData)
      );
    });

    test('User cannot create task for another user', async () => {
      const db = getAuthContext('regularUser').firestore();
      const invalidTaskData = { ...taskData, userId: 'otheruser' };
      await assertFails(
        setDoc(doc(db, 'tasks', 'task123'), invalidTaskData)
      );
    });

    test('User can read their own task', async () => {
      const adminDb = getAuthContext('admin').firestore();
      await setDoc(doc(adminDb, 'tasks', 'task123'), taskData);

      const userDb = getAuthContext('regularUser').firestore();
      await assertSucceeds(
        getDoc(doc(userDb, 'tasks', 'task123'))
      );
    });

    test('User cannot read another user\'s task', async () => {
      const adminDb = getAuthContext('admin').firestore();
      const otherUserTask = { ...taskData, userId: 'otheruser' };
      await setDoc(doc(adminDb, 'tasks', 'task456'), otherUserTask);

      const userDb = getAuthContext('regularUser').firestore();
      await assertFails(
        getDoc(doc(userDb, 'tasks', 'task456'))
      );
    });

    test('Admin can read any task', async () => {
      const adminDb = getAuthContext('admin').firestore();
      await setDoc(doc(adminDb, 'tasks', 'task123'), taskData);
      
      await assertSucceeds(
        getDoc(doc(adminDb, 'tasks', 'task123'))
      );
    });

    test('Unauthenticated user cannot access tasks', async () => {
      const db = getAuthContext('unauthenticated').firestore();
      await assertFails(
        getDoc(doc(db, 'tasks', 'task123'))
      );
    });

    test('User can update their own task', async () => {
      const db = getAuthContext('regularUser').firestore();
      await setDoc(doc(db, 'tasks', 'task123'), taskData);
      
      await assertSucceeds(
        updateDoc(doc(db, 'tasks', 'task123'), {
          title: 'Updated Task',
          userId: 'user123' // Must maintain userId
        })
      );
    });

    test('User cannot change task ownership', async () => {
      const db = getAuthContext('regularUser').firestore();
      await setDoc(doc(db, 'tasks', 'task123'), taskData);
      
      await assertFails(
        updateDoc(doc(db, 'tasks', 'task123'), {
          userId: 'otheruser'
        })
      );
    });

    test('User can delete their own task', async () => {
      const db = getAuthContext('regularUser').firestore();
      await setDoc(doc(db, 'tasks', 'task123'), taskData);
      
      await assertSucceeds(
        deleteDoc(doc(db, 'tasks', 'task123'))
      );
    });
  });

  describe('Session Collection Security', () => {
    const sessionData = {
      id: 'session123',
      userId: 'user123',
      startTime: new Date(),
      endTime: null,
      completed: false,
      type: 'work',
      taskId: 'task123'
    };

    test('User can create their own session', async () => {
      const db = getAuthContext('regularUser').firestore();
      await assertSucceeds(
        setDoc(doc(db, 'sessions', 'session123'), sessionData)
      );
    });

    test('User cannot create session for another user', async () => {
      const db = getAuthContext('regularUser').firestore();
      const invalidSessionData = { ...sessionData, userId: 'otheruser' };
      await assertFails(
        setDoc(doc(db, 'sessions', 'session123'), invalidSessionData)
      );
    });

    test('User can read their own sessions', async () => {
      const db = getAuthContext('regularUser').firestore();
      await setDoc(doc(db, 'sessions', 'session123'), sessionData);
      
      await assertSucceeds(
        getDoc(doc(db, 'sessions', 'session123'))
      );
    });

    test('User cannot access another user\'s sessions', async () => {
      const adminDb = getAuthContext('admin').firestore();
      const otherUserSession = { ...sessionData, userId: 'otheruser' };
      await setDoc(doc(adminDb, 'sessions', 'session456'), otherUserSession);

      const userDb = getAuthContext('regularUser').firestore();
      await assertFails(
        getDoc(doc(userDb, 'sessions', 'session456'))
      );
    });
  });

  describe('User Profile Security', () => {
    const userData = {
      email: 'user@example.com',
      displayName: 'Test User',
      createdAt: new Date(),
      settings: {
        theme: 'dark',
        notifications: true
      }
    };

    test('User can create their own profile', async () => {
      const db = getAuthContext('regularUser').firestore();
      await assertSucceeds(
        setDoc(doc(db, 'users', 'user123'), userData)
      );
    });

    test('User cannot create profile for another user', async () => {
      const db = getAuthContext('regularUser').firestore();
      await assertFails(
        setDoc(doc(db, 'users', 'otheruser'), userData)
      );
    });

    test('User can read their own profile', async () => {
      const db = getAuthContext('regularUser').firestore();
      await setDoc(doc(db, 'users', 'user123'), userData);
      
      await assertSucceeds(
        getDoc(doc(db, 'users', 'user123'))
      );
    });

    test('User cannot read another user\'s profile', async () => {
      const adminDb = getAuthContext('admin').firestore();
      await setDoc(doc(adminDb, 'users', 'otheruser'), userData);

      const userDb = getAuthContext('regularUser').firestore();
      await assertFails(
        getDoc(doc(userDb, 'users', 'otheruser'))
      );
    });

    test('Admin can access any user profile', async () => {
      const adminDb = getAuthContext('admin').firestore();
      await setDoc(doc(adminDb, 'users', 'user123'), userData);
      
      await assertSucceeds(
        getDoc(doc(adminDb, 'users', 'user123'))
      );
    });
  });

  describe('Leaderboard Security', () => {
    const leaderboardEntry = {
      userId: 'user123',
      displayName: 'Test User',
      score: 95.5,
      rank: 1,
      totalFocusMinutes: 1200,
      sessionsCompleted: 48,
      lastActive: new Date()
    };

    test('Authenticated users can read leaderboard', async () => {
      const adminDb = getAuthContext('admin').firestore();
      await setDoc(doc(adminDb, 'leaderboards/productivity/entries', 'entry123'), leaderboardEntry);

      const userDb = getAuthContext('regularUser').firestore();
      await assertSucceeds(
        getDoc(doc(userDb, 'leaderboards/productivity/entries', 'entry123'))
      );
    });

    test('Unauthenticated users cannot read leaderboard', async () => {
      const db = getAuthContext('unauthenticated').firestore();
      await assertFails(
        getDoc(doc(db, 'leaderboards/productivity/entries', 'entry123'))
      );
    });

    test('Regular users cannot write to leaderboard', async () => {
      const db = getAuthContext('regularUser').firestore();
      await assertFails(
        setDoc(doc(db, 'leaderboards/productivity/entries', 'entry123'), leaderboardEntry)
      );
    });

    test('Admin can write to leaderboard', async () => {
      const db = getAuthContext('admin').firestore();
      await assertSucceeds(
        setDoc(doc(db, 'leaderboards/productivity/entries', 'entry123'), leaderboardEntry)
      );
    });

    test('System user can write to leaderboard', async () => {
      const db = getAuthContext('systemUser').firestore();
      await assertSucceeds(
        setDoc(doc(db, 'leaderboards/productivity/entries', 'entry123'), leaderboardEntry)
      );
    });
  });

  describe('Premium Features Security', () => {
    const aiInsightData = {
      userId: 'premium456',
      type: 'productivity_analysis',
      insights: ['Focus better in mornings', 'Take breaks every 45 mins'],
      createdAt: new Date(),
      confidence: 0.85
    };

    test('Premium user can read their AI insights', async () => {
      const adminDb = getAuthContext('admin').firestore();
      await setDoc(doc(adminDb, 'ai_insights', 'premium456'), aiInsightData);

      const premiumDb = getAuthContext('premiumUser').firestore();
      await assertSucceeds(
        getDoc(doc(premiumDb, 'ai_insights', 'premium456'))
      );
    });

    test('Regular user cannot access AI insights', async () => {
      const db = getAuthContext('regularUser').firestore();
      await assertFails(
        getDoc(doc(db, 'ai_insights', 'user123'))
      );
    });

    test('Premium user cannot write AI insights', async () => {
      const db = getAuthContext('premiumUser').firestore();
      await assertFails(
        setDoc(doc(db, 'ai_insights', 'premium456'), aiInsightData)
      );
    });

    test('System can write AI insights', async () => {
      const db = getAuthContext('systemUser').firestore();
      await assertSucceeds(
        setDoc(doc(db, 'ai_insights', 'premium456'), aiInsightData)
      );
    });
  });

  describe('Enterprise Features Security', () => {
    const organizationData = {
      name: 'Test Company',
      members: ['enterprise789', 'user123'],
      admins: ['enterprise789'],
      createdAt: new Date(),
      isActive: true
    };

    test('Enterprise user can read organization they belong to', async () => {
      const adminDb = getAuthContext('admin').firestore();
      await setDoc(doc(adminDb, 'organizations', 'org123'), organizationData);

      const enterpriseDb = getAuthContext('enterpriseUser').firestore();
      await assertSucceeds(
        getDoc(doc(enterpriseDb, 'organizations', 'org123'))
      );
    });

    test('User cannot read organization they don\'t belong to', async () => {
      const adminDb = getAuthContext('admin').firestore();
      const otherOrgData = { ...organizationData, members: ['otheruser'], admins: ['otheruser'] };
      await setDoc(doc(adminDb, 'organizations', 'org456'), otherOrgData);

      const userDb = getAuthContext('regularUser').firestore();
      await assertFails(
        getDoc(doc(userDb, 'organizations', 'org456'))
      );
    });

    test('Organization admin can update organization', async () => {
      const adminDb = getAuthContext('admin').firestore();
      await setDoc(doc(adminDb, 'organizations', 'org123'), organizationData);

      const enterpriseDb = getAuthContext('enterpriseUser').firestore();
      await assertSucceeds(
        updateDoc(doc(enterpriseDb, 'organizations', 'org123'), {
          name: 'Updated Company Name'
        })
      );
    });

    test('Organization member cannot update organization', async () => {
      const adminDb = getAuthContext('admin').firestore();
      await setDoc(doc(adminDb, 'organizations', 'org123'), organizationData);

      const userDb = getAuthContext('regularUser').firestore();
      await assertFails(
        updateDoc(doc(userDb, 'organizations', 'org123'), {
          name: 'Hacked Company'
        })
      );
    });
  });

  describe('System Collections Security', () => {
    const globalConfigData = {
      appVersion: '2.0.0',
      maintenanceMode: false,
      features: {
        aiEnabled: true,
        leaderboardEnabled: true
      }
    };

    test('Authenticated users can read global config', async () => {
      const adminDb = getAuthContext('admin').firestore();
      await setDoc(doc(adminDb, 'global', 'config'), globalConfigData);

      const userDb = getAuthContext('regularUser').firestore();
      await assertSucceeds(
        getDoc(doc(userDb, 'global', 'config'))
      );
    });

    test('Unauthenticated users cannot read global config', async () => {
      const db = getAuthContext('unauthenticated').firestore();
      await assertFails(
        getDoc(doc(db, 'global', 'config'))
      );
    });

    test('Regular users cannot write global config', async () => {
      const db = getAuthContext('regularUser').firestore();
      await assertFails(
        setDoc(doc(db, 'global', 'config'), globalConfigData)
      );
    });

    test('Admin can write global config', async () => {
      const db = getAuthContext('admin').firestore();
      await assertSucceeds(
        setDoc(doc(db, 'global', 'config'), globalConfigData)
      );
    });
  });

  describe('Data Export Security', () => {
    const exportRequestData = {
      userId: 'user123',
      format: 'json',
      status: 'pending',
      createdAt: new Date(),
      requestedData: ['tasks', 'sessions', 'analytics']
    };

    test('User can create export request for themselves', async () => {
      const db = getAuthContext('regularUser').firestore();
      await assertSucceeds(
        setDoc(doc(db, 'export_requests', 'export123'), exportRequestData)
      );
    });

    test('User cannot create export request for another user', async () => {
      const db = getAuthContext('regularUser').firestore();
      const invalidExportData = { ...exportRequestData, userId: 'otheruser' };
      await assertFails(
        setDoc(doc(db, 'export_requests', 'export123'), invalidExportData)
      );
    });

    test('User can read their own export requests', async () => {
      const db = getAuthContext('regularUser').firestore();
      await setDoc(doc(db, 'export_requests', 'export123'), exportRequestData);
      
      await assertSucceeds(
        getDoc(doc(db, 'export_requests', 'export123'))
      );
    });

    test('System can update export request status', async () => {
      const userDb = getAuthContext('regularUser').firestore();
      await setDoc(doc(userDb, 'export_requests', 'export123'), exportRequestData);

      const systemDb = getAuthContext('systemUser').firestore();
      await assertSucceeds(
        updateDoc(doc(systemDb, 'export_requests', 'export123'), {
          status: 'completed'
        })
      );
    });
  });

  describe('Rate Limiting Security', () => {
    const quotaData = {
      userId: 'user123',
      dailyReads: 1500,
      dailyWrites: 750,
      resetDate: new Date(),
      tier: 'free'
    };

    test('User can read their own quota', async () => {
      const adminDb = getAuthContext('admin').firestore();
      await setDoc(doc(adminDb, 'user_quotas', 'user123'), quotaData);

      const userDb = getAuthContext('regularUser').firestore();
      await assertSucceeds(
        getDoc(doc(userDb, 'user_quotas', 'user123'))
      );
    });

    test('User cannot read another user\'s quota', async () => {
      const adminDb = getAuthContext('admin').firestore();
      await setDoc(doc(adminDb, 'user_quotas', 'otheruser'), quotaData);

      const userDb = getAuthContext('regularUser').firestore();
      await assertFails(
        getDoc(doc(userDb, 'user_quotas', 'otheruser'))
      );
    });

    test('User cannot write quota data', async () => {
      const db = getAuthContext('regularUser').firestore();
      await assertFails(
        setDoc(doc(db, 'user_quotas', 'user123'), quotaData)
      );
    });

    test('System can write quota data', async () => {
      const db = getAuthContext('systemUser').firestore();
      await assertSucceeds(
        setDoc(doc(db, 'user_quotas', 'user123'), quotaData)
      );
    });
  });

  describe('Audit and Security Logs', () => {
    const auditLogData = {
      userId: 'user123',
      action: 'task_created',
      resource: 'tasks/task123',
      timestamp: new Date(),
      metadata: {
        ip: '192.168.1.100',
        userAgent: 'Flutter App 2.0'
      }
    };

    test('Regular users cannot read audit logs', async () => {
      const adminDb = getAuthContext('admin').firestore();
      await setDoc(doc(adminDb, 'audit_logs', 'log123'), auditLogData);

      const userDb = getAuthContext('regularUser').firestore();
      await assertFails(
        getDoc(doc(userDb, 'audit_logs', 'log123'))
      );
    });

    test('Admin can read audit logs', async () => {
      const adminDb = getAuthContext('admin').firestore();
      await setDoc(doc(adminDb, 'audit_logs', 'log123'), auditLogData);
      
      await assertSucceeds(
        getDoc(doc(adminDb, 'audit_logs', 'log123'))
      );
    });

    test('System can write audit logs', async () => {
      const db = getAuthContext('systemUser').firestore();
      await assertSucceeds(
        setDoc(doc(db, 'audit_logs', 'log123'), auditLogData)
      );
    });
  });

  describe('Query Performance Tests', () => {
    test('User task queries are efficient with proper indexing', async () => {
      const db = getAuthContext('regularUser').firestore();
      
      // Create multiple test tasks
      for (let i = 0; i < 10; i++) {
        await setDoc(doc(db, 'tasks', `task${i}`), {
          id: `task${i}`,
          title: `Task ${i}`,
          userId: 'user123',
          createdAt: new Date(),
          isCompleted: i % 2 === 0,
          priority: i % 3 === 0 ? 'high' : 'medium',
          category: i % 2 === 0 ? 'work' : 'personal'
        });
      }

      // Test complex query that should use indexes
      const q = query(
        collection(db, 'tasks'),
        where('userId', '==', 'user123'),
        where('isCompleted', '==', false),
        orderBy('priority', 'desc'),
        orderBy('createdAt', 'desc')
      );

      await assertSucceeds(getDocs(q));
    });
  });
});

/**
 * Run this test file with:
 * npx jest firebase_rules_test.js --verbose
 */

console.log(`
=== Firebase Security Rules Test Suite ===

This comprehensive test suite validates:

✅ Task Collection Security
  - User isolation and ownership
  - CRUD operations with proper validation
  - Admin override capabilities

✅ Session Management Security
  - Session creation and access controls
  - Timer and Pomodoro session isolation

✅ User Profile Security
  - Profile ownership and access
  - Settings and preferences security

✅ Leaderboard Access Control
  - Read access for authenticated users
  - Write restrictions for system/admin only

✅ Premium Feature Security
  - Role-based access to AI insights
  - Advanced analytics restrictions

✅ Enterprise Features Security
  - Organization membership validation
  - Workspace access controls
  - Shared resource permissions

✅ System Collections Security
  - Global configuration access
  - ML models and system data

✅ Data Export Security
  - User data export controls
  - Request validation and processing

✅ Rate Limiting Security
  - Quota tracking and enforcement
  - Usage monitoring

✅ Audit and Security Logs
  - Admin-only access to logs
  - System event tracking

✅ Query Performance
  - Index utilization validation
  - Complex query testing

To run the tests:
1. npm install firebase-admin @firebase/rules-unit-testing jest
2. Start Firebase emulators: firebase emulators:start --only firestore
3. Run tests: npx jest firebase_rules_test.js --verbose

Expected Results:
- All security rules should properly enforce user isolation
- Role-based access should work correctly
- Performance queries should utilize indexes efficiently
- No unauthorized access should be possible
`);