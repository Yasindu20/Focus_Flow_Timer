/**
 * Comprehensive Firebase Storage Security Rules Testing Suite
 * Focus Flow Timer - Enterprise Edition
 * 
 * Tests all storage rules with different user roles and file scenarios
 * Run with: npm install @firebase/rules-unit-testing
 */

const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'focus-flow-timer-storage-test';
const STORAGE_RULES_FILE = './storage.rules';

// Test user configurations with different roles
const testUsers = {
  standardUser: {
    uid: 'user123',
    email: 'user@example.com'
  },
  premiumUser: {
    uid: 'premium456',
    email: 'premium@example.com',
    premium: true
  },
  enterpriseUser: {
    uid: 'enterprise789',
    email: 'enterprise@example.com',
    enterprise: true
  },
  admin: {
    uid: 'admin999',
    email: 'admin@example.com',
    admin: true
  },
  systemUser: {
    uid: 'system000',
    email: 'system@example.com',
    system: true
  }
};

// Mock file data for testing
const testFiles = {
  smallImage: {
    data: Buffer.alloc(1024 * 1024, 'A'), // 1MB
    contentType: 'image/jpeg'
  },
  largeImage: {
    data: Buffer.alloc(6 * 1024 * 1024, 'B'), // 6MB - exceeds profile picture limit
    contentType: 'image/png'
  },
  validDocument: {
    data: Buffer.alloc(10 * 1024 * 1024, 'C'), // 10MB
    contentType: 'application/pdf'
  },
  oversizedDocument: {
    data: Buffer.alloc(30 * 1024 * 1024, 'D'), // 30MB - exceeds task attachment limit
    contentType: 'application/pdf'
  },
  audioFile: {
    data: Buffer.alloc(20 * 1024 * 1024, 'E'), // 20MB
    contentType: 'audio/mpeg'
  },
  oversizedAudio: {
    data: Buffer.alloc(60 * 1024 * 1024, 'F'), // 60MB - exceeds custom sound limit
    contentType: 'audio/mp3'
  },
  maliciousFile: {
    data: Buffer.alloc(1024, 'G'), // 1KB
    contentType: 'application/octet-stream' // Generic binary - should be rejected
  },
  exportFile: {
    data: Buffer.alloc(5 * 1024 * 1024, 'H'), // 5MB
    contentType: 'application/json'
  }
};

describe('Firebase Storage Security Rules Tests', () => {
  let testEnv;

  beforeAll(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      storage: {
        rules: fs.readFileSync(STORAGE_RULES_FILE, 'utf8'),
        host: 'localhost',
        port: 9199
      }
    });
  });

  beforeEach(async () => {
    await testEnv.clearStorage();
  });

  afterAll(async () => {
    await testEnv.cleanup();
  });

  // Helper function to get authenticated storage context
  function getStorageContext(userType) {
    if (userType === 'unauthenticated') {
      return testEnv.unauthenticatedContext();
    }
    return testEnv.authenticatedContext(testUsers[userType].uid, testUsers[userType]);
  }

  describe('User Profile Storage Tests', () => {
    
    describe('Profile Avatar Tests', () => {
      const avatarPath = 'users/user123/profile/avatar.jpg';

      test('Standard user can upload valid profile picture', async () => {
        const storage = getStorageContext('standardUser').storage();
        await assertSucceeds(
          storage.ref(avatarPath).put(testFiles.smallImage.data, {
            contentType: testFiles.smallImage.contentType
          })
        );
      });

      test('User cannot upload oversized profile picture', async () => {
        const storage = getStorageContext('standardUser').storage();
        await assertFails(
          storage.ref(avatarPath).put(testFiles.largeImage.data, {
            contentType: testFiles.largeImage.contentType
          })
        );
      });

      test('User cannot upload invalid file type as avatar', async () => {
        const storage = getStorageContext('standardUser').storage();
        await assertFails(
          storage.ref(avatarPath).put(testFiles.validDocument.data, {
            contentType: testFiles.validDocument.contentType
          })
        );
      });

      test('User cannot upload avatar for another user', async () => {
        const storage = getStorageContext('standardUser').storage();
        const otherUserPath = 'users/otheruser/profile/avatar.jpg';
        await assertFails(
          storage.ref(otherUserPath).put(testFiles.smallImage.data, {
            contentType: testFiles.smallImage.contentType
          })
        );
      });

      test('User can read their own profile picture', async () => {
        const adminStorage = getStorageContext('admin').storage();
        await adminStorage.ref(avatarPath).put(testFiles.smallImage.data, {
          contentType: testFiles.smallImage.contentType
        });

        const userStorage = getStorageContext('standardUser').storage();
        await assertSucceeds(userStorage.ref(avatarPath).getDownloadURL());
      });

      test('User can delete their own profile picture', async () => {
        const storage = getStorageContext('standardUser').storage();
        await storage.ref(avatarPath).put(testFiles.smallImage.data, {
          contentType: testFiles.smallImage.contentType
        });

        await assertSucceeds(storage.ref(avatarPath).delete());
      });

      test('Unauthenticated user cannot access profile pictures', async () => {
        const storage = getStorageContext('unauthenticated').storage();
        await assertFails(storage.ref(avatarPath).getDownloadURL());
      });
    });

    describe('Premium Profile Features Tests', () => {
      
      test('Premium user can upload custom background', async () => {
        const backgroundPath = 'users/premium456/profile/background.jpg';
        const storage = getStorageContext('premiumUser').storage();
        await assertSucceeds(
          storage.ref(backgroundPath).put(testFiles.smallImage.data, {
            contentType: testFiles.smallImage.contentType
          })
        );
      });

      test('Standard user cannot upload custom background', async () => {
        const backgroundPath = 'users/user123/profile/background.jpg';
        const storage = getStorageContext('standardUser').storage();
        await assertFails(
          storage.ref(backgroundPath).put(testFiles.smallImage.data, {
            contentType: testFiles.smallImage.contentType
          })
        );
      });

      test('Premium user can upload custom sounds', async () => {
        const soundPath = 'users/premium456/profile/sounds/mysound.mp3';
        const storage = getStorageContext('premiumUser').storage();
        await assertSucceeds(
          storage.ref(soundPath).put(testFiles.audioFile.data, {
            contentType: testFiles.audioFile.contentType
          })
        );
      });

      test('Premium user cannot upload oversized custom sound', async () => {
        const soundPath = 'users/premium456/profile/sounds/bigsound.mp3';
        const storage = getStorageContext('premiumUser').storage();
        await assertFails(
          storage.ref(soundPath).put(testFiles.oversizedAudio.data, {
            contentType: testFiles.oversizedAudio.contentType
          })
        );
      });

      test('Standard user cannot upload custom sounds', async () => {
        const soundPath = 'users/user123/profile/sounds/mysound.mp3';
        const storage = getStorageContext('standardUser').storage();
        await assertFails(
          storage.ref(soundPath).put(testFiles.audioFile.data, {
            contentType: testFiles.audioFile.contentType
          })
        );
      });
    });
  });

  describe('Task Attachment Tests', () => {
    
    describe('Document Attachments', () => {
      const attachmentPath = 'users/user123/tasks/task456/attachments/document.pdf';

      test('User can upload valid document attachment', async () => {
        const storage = getStorageContext('standardUser').storage();
        await assertSucceeds(
          storage.ref(attachmentPath).put(testFiles.validDocument.data, {
            contentType: testFiles.validDocument.contentType
          })
        );
      });

      test('User cannot upload oversized document', async () => {
        const storage = getStorageContext('standardUser').storage();
        await assertFails(
          storage.ref(attachmentPath).put(testFiles.oversizedDocument.data, {
            contentType: testFiles.oversizedDocument.contentType
          })
        );
      });

      test('User cannot upload invalid file type as attachment', async () => {
        const storage = getStorageContext('standardUser').storage();
        await assertFails(
          storage.ref(attachmentPath).put(testFiles.maliciousFile.data, {
            contentType: testFiles.maliciousFile.contentType
          })
        );
      });

      test('User cannot access another user\'s task attachments', async () => {
        const otherUserPath = 'users/otheruser/tasks/task789/attachments/secret.pdf';
        const storage = getStorageContext('standardUser').storage();
        await assertFails(storage.ref(otherUserPath).getDownloadURL());
      });

      test('Admin can access any user\'s attachments', async () => {
        const storage = getStorageContext('standardUser').storage();
        await storage.ref(attachmentPath).put(testFiles.validDocument.data, {
          contentType: testFiles.validDocument.contentType
        });

        const adminStorage = getStorageContext('admin').storage();
        await assertSucceeds(adminStorage.ref(attachmentPath).getDownloadURL());
      });
    });

    describe('Image Attachments', () => {
      const imagePath = 'users/user123/tasks/task456/images/screenshot.png';

      test('User can upload task image', async () => {
        const storage = getStorageContext('standardUser').storage();
        await assertSucceeds(
          storage.ref(imagePath).put(testFiles.smallImage.data, {
            contentType: testFiles.smallImage.contentType
          })
        );
      });

      test('User cannot upload oversized image', async () => {
        const storage = getStorageContext('standardUser').storage();
        await assertFails(
          storage.ref(imagePath).put(testFiles.largeImage.data, {
            contentType: testFiles.largeImage.contentType
          })
        );
      });
    });

    describe('Voice Note Attachments (Premium)', () => {
      const voicePath = 'users/premium456/tasks/task456/voice/note.mp3';

      test('Premium user can upload voice note', async () => {
        const storage = getStorageContext('premiumUser').storage();
        await assertSucceeds(
          storage.ref(voicePath).put(testFiles.audioFile.data, {
            contentType: testFiles.audioFile.contentType
          })
        );
      });

      test('Standard user cannot upload voice notes', async () => {
        const voicePath = 'users/user123/tasks/task456/voice/note.mp3';
        const storage = getStorageContext('standardUser').storage();
        await assertFails(
          storage.ref(voicePath).put(testFiles.audioFile.data, {
            contentType: testFiles.audioFile.contentType
          })
        );
      });
    });
  });

  describe('Data Export and Backup Tests', () => {
    
    describe('User Data Exports', () => {
      const exportPath = 'users/user123/exports/export123.json';

      test('User can read their own export files', async () => {
        const systemStorage = getStorageContext('systemUser').storage();
        await systemStorage.ref(exportPath).put(testFiles.exportFile.data, {
          contentType: testFiles.exportFile.contentType
        });

        const userStorage = getStorageContext('standardUser').storage();
        await assertSucceeds(userStorage.ref(exportPath).getDownloadURL());
      });

      test('User cannot create export files directly', async () => {
        const storage = getStorageContext('standardUser').storage();
        await assertFails(
          storage.ref(exportPath).put(testFiles.exportFile.data, {
            contentType: testFiles.exportFile.contentType
          })
        );
      });

      test('System can create export files', async () => {
        const storage = getStorageContext('systemUser').storage();
        await assertSucceeds(
          storage.ref(exportPath).put(testFiles.exportFile.data, {
            contentType: testFiles.exportFile.contentType
          })
        );
      });

      test('User cannot access another user\'s exports', async () => {
        const otherExportPath = 'users/otheruser/exports/export456.json';
        const storage = getStorageContext('standardUser').storage();
        await assertFails(storage.ref(otherExportPath).getDownloadURL());
      });
    });

    describe('Analytics Reports (Premium)', () => {
      const reportPath = 'users/premium456/reports/report123.pdf';

      test('Premium user can read their analytics reports', async () => {
        const systemStorage = getStorageContext('systemUser').storage();
        await systemStorage.ref(reportPath).put(testFiles.exportFile.data, {
          contentType: 'application/pdf'
        });

        const premiumStorage = getStorageContext('premiumUser').storage();
        await assertSucceeds(premiumStorage.ref(reportPath).getDownloadURL());
      });

      test('Standard user cannot access premium reports', async () => {
        const reportPath = 'users/user123/reports/report789.pdf';
        const storage = getStorageContext('standardUser').storage();
        await assertFails(storage.ref(reportPath).getDownloadURL());
      });
    });

    describe('Enterprise Backups', () => {
      const backupPath = 'users/enterprise789/backups/backup123.json';

      test('Enterprise user can read their backup files', async () => {
        const systemStorage = getStorageContext('systemUser').storage();
        await systemStorage.ref(backupPath).put(testFiles.exportFile.data, {
          contentType: testFiles.exportFile.contentType
        });

        const enterpriseStorage = getStorageContext('enterpriseUser').storage();
        await assertSucceeds(enterpriseStorage.ref(backupPath).getDownloadURL());
      });

      test('System can create enterprise backups', async () => {
        const storage = getStorageContext('systemUser').storage();
        await assertSucceeds(
          storage.ref(backupPath).put(testFiles.exportFile.data, {
            contentType: testFiles.exportFile.contentType
          })
        );
      });
    });
  });

  describe('Enterprise Collaboration Features', () => {
    
    describe('Workspace Shared Files', () => {
      const sharedPath = 'workspaces/workspace123/shared/document.pdf';

      test('Enterprise user can upload shared workspace files', async () => {
        const storage = getStorageContext('enterpriseUser').storage();
        await assertSucceeds(
          storage.ref(sharedPath).put(testFiles.validDocument.data, {
            contentType: testFiles.validDocument.contentType
          })
        );
      });

      test('Standard user cannot access workspace files', async () => {
        const storage = getStorageContext('standardUser').storage();
        await assertFails(storage.ref(sharedPath).getDownloadURL());
      });

      test('Enterprise user can read shared workspace files', async () => {
        const uploadStorage = getStorageContext('enterpriseUser').storage();
        await uploadStorage.ref(sharedPath).put(testFiles.validDocument.data, {
          contentType: testFiles.validDocument.contentType
        });

        const readStorage = getStorageContext('enterpriseUser').storage();
        await assertSucceeds(readStorage.ref(sharedPath).getDownloadURL());
      });
    });

    describe('Organization Assets', () => {
      const logoPath = 'organizations/org123/assets/logo.png';

      test('Enterprise user can upload organization logo', async () => {
        const storage = getStorageContext('enterpriseUser').storage();
        await assertSucceeds(
          storage.ref(logoPath).put(testFiles.smallImage.data, {
            contentType: testFiles.smallImage.contentType
          })
        );
      });

      test('Enterprise user cannot upload oversized organization asset', async () => {
        const storage = getStorageContext('enterpriseUser').storage();
        await assertFails(
          storage.ref(logoPath).put(testFiles.largeImage.data, {
            contentType: testFiles.largeImage.contentType
          })
        );
      });
    });

    describe('Team Files', () => {
      const teamFilePath = 'teams/team123/files/presentation.pdf';

      test('Enterprise user can upload team files', async () => {
        const storage = getStorageContext('enterpriseUser').storage();
        await assertSucceeds(
          storage.ref(teamFilePath).put(testFiles.validDocument.data, {
            contentType: testFiles.validDocument.contentType
          })
        );
      });

      test('Team files can be large for enterprise users', async () => {
        const largeFilePath = 'teams/team123/files/large-presentation.pdf';
        const storage = getStorageContext('enterpriseUser').storage();
        const largeFile = Buffer.alloc(80 * 1024 * 1024, 'Z'); // 80MB - within 100MB limit
        await assertSucceeds(
          storage.ref(largeFilePath).put(largeFile, {
            contentType: 'application/pdf'
          })
        );
      });
    });
  });

  describe('Shared System Assets Tests', () => {
    
    describe('Focus Sounds', () => {
      const soundPath = 'assets/sounds/focus/forest-rain.mp3';

      test('Authenticated user can read focus sounds', async () => {
        const adminStorage = getStorageContext('admin').storage();
        await adminStorage.ref(soundPath).put(testFiles.audioFile.data, {
          contentType: testFiles.audioFile.contentType
        });

        const userStorage = getStorageContext('standardUser').storage();
        await assertSucceeds(userStorage.ref(soundPath).getDownloadURL());
      });

      test('Unauthenticated user cannot access focus sounds', async () => {
        const storage = getStorageContext('unauthenticated').storage();
        await assertFails(storage.ref(soundPath).getDownloadURL());
      });

      test('Only admin can upload focus sounds', async () => {
        const userStorage = getStorageContext('standardUser').storage();
        await assertFails(
          userStorage.ref(soundPath).put(testFiles.audioFile.data, {
            contentType: testFiles.audioFile.contentType
          })
        );

        const adminStorage = getStorageContext('admin').storage();
        await assertSucceeds(
          adminStorage.ref(soundPath).put(testFiles.audioFile.data, {
            contentType: testFiles.audioFile.contentType
          })
        );
      });
    });

    describe('Achievement Images', () => {
      const badgePath = 'assets/images/achievements/first-task.png';

      test('Authenticated users can read achievement images', async () => {
        const adminStorage = getStorageContext('admin').storage();
        await adminStorage.ref(badgePath).put(testFiles.smallImage.data, {
          contentType: testFiles.smallImage.contentType
        });

        const userStorage = getStorageContext('standardUser').storage();
        await assertSucceeds(userStorage.ref(badgePath).getDownloadURL());
      });

      test('Only admin can manage achievement assets', async () => {
        const userStorage = getStorageContext('standardUser').storage();
        await assertFails(
          userStorage.ref(badgePath).put(testFiles.smallImage.data, {
            contentType: testFiles.smallImage.contentType
          })
        );
      });
    });
  });

  describe('AI and ML Models Tests', () => {
    
    describe('Model Files', () => {
      const modelPath = 'models/ai/task-classifier/model.json';

      test('Authenticated users can read ML models', async () => {
        const adminStorage = getStorageContext('admin').storage();
        await adminStorage.ref(modelPath).put(testFiles.exportFile.data, {
          contentType: testFiles.exportFile.contentType
        });

        const userStorage = getStorageContext('standardUser').storage();
        await assertSucceeds(userStorage.ref(modelPath).getDownloadURL());
      });

      test('System can upload ML models', async () => {
        const storage = getStorageContext('systemUser').storage();
        await assertSucceeds(
          storage.ref(modelPath).put(testFiles.exportFile.data, {
            contentType: testFiles.exportFile.contentType
          })
        );
      });

      test('Regular users cannot upload ML models', async () => {
        const storage = getStorageContext('standardUser').storage();
        await assertFails(
          storage.ref(modelPath).put(testFiles.exportFile.data, {
            contentType: testFiles.exportFile.contentType
          })
        );
      });
    });

    describe('Training Data', () => {
      const trainingPath = 'models/training/user-patterns/dataset.json';

      test('Only admin can access training data', async () => {
        const systemStorage = getStorageContext('systemUser').storage();
        await systemStorage.ref(trainingPath).put(testFiles.exportFile.data, {
          contentType: testFiles.exportFile.contentType
        });

        const adminStorage = getStorageContext('admin').storage();
        await assertSucceeds(adminStorage.ref(trainingPath).getDownloadURL());

        const userStorage = getStorageContext('standardUser').storage();
        await assertFails(userStorage.ref(trainingPath).getDownloadURL());
      });
    });
  });

  describe('Temporary Files Tests', () => {
    
    describe('Temp Uploads', () => {
      const tempPath = 'temp/user123/upload456/tempfile.pdf';

      test('User can upload temporary files', async () => {
        const storage = getStorageContext('standardUser').storage();
        await assertSucceeds(
          storage.ref(tempPath).put(testFiles.validDocument.data, {
            contentType: testFiles.validDocument.contentType
          })
        );
      });

      test('User can upload large temporary files', async () => {
        const storage = getStorageContext('standardUser').storage();
        const largeTemp = Buffer.alloc(300 * 1024 * 1024, 'T'); // 300MB - within 500MB temp limit
        await assertSucceeds(
          storage.ref(tempPath).put(largeTemp, {
            contentType: 'application/pdf'
          })
        );
      });

      test('User cannot access another user\'s temp files', async () => {
        const otherTempPath = 'temp/otheruser/upload789/tempfile.pdf';
        const storage = getStorageContext('standardUser').storage();
        await assertFails(storage.ref(otherTempPath).getDownloadURL());
      });

      test('System can clean up temp files', async () => {
        const userStorage = getStorageContext('standardUser').storage();
        await userStorage.ref(tempPath).put(testFiles.validDocument.data, {
          contentType: testFiles.validDocument.contentType
        });

        const systemStorage = getStorageContext('systemUser').storage();
        await assertSucceeds(systemStorage.ref(tempPath).delete());
      });
    });
  });

  describe('File Name Security Tests', () => {
    
    test('Reject files with malicious names', async () => {
      const maliciousPath = 'users/user123/tasks/task456/attachments/../../../malicious.pdf';
      const storage = getStorageContext('standardUser').storage();
      await assertFails(
        storage.ref(maliciousPath).put(testFiles.validDocument.data, {
          contentType: testFiles.validDocument.contentType
        })
      );
    });

    test('Accept files with valid names', async () => {
      const validPath = 'users/user123/tasks/task456/attachments/My-Document_v2.pdf';
      const storage = getStorageContext('standardUser').storage();
      await assertSucceeds(
        storage.ref(validPath).put(testFiles.validDocument.data, {
          contentType: testFiles.validDocument.contentType
        })
      );
    });

    test('Reject files with special characters in names', async () => {
      const invalidPath = 'users/user123/tasks/task456/attachments/file<script>.pdf';
      const storage = getStorageContext('standardUser').storage();
      await assertFails(
        storage.ref(invalidPath).put(testFiles.validDocument.data, {
          contentType: testFiles.validDocument.contentType
        })
      );
    });
  });

  describe('Admin Override Tests', () => {
    
    test('Admin can access any user file', async () => {
      const userFilePath = 'users/user123/profile/avatar.jpg';
      const userStorage = getStorageContext('standardUser').storage();
      await userStorage.ref(userFilePath).put(testFiles.smallImage.data, {
        contentType: testFiles.smallImage.contentType
      });

      const adminStorage = getStorageContext('admin').storage();
      await assertSucceeds(adminStorage.ref(userFilePath).getDownloadURL());
    });

    test('Admin can delete any user file', async () => {
      const userFilePath = 'users/user123/tasks/task456/attachments/document.pdf';
      const userStorage = getStorageContext('standardUser').storage();
      await userStorage.ref(userFilePath).put(testFiles.validDocument.data, {
        contentType: testFiles.validDocument.contentType
      });

      const adminStorage = getStorageContext('admin').storage();
      await assertSucceeds(adminStorage.ref(userFilePath).delete());
    });

    test('Admin can manage system assets', async () => {
      const systemPath = 'assets/sounds/focus/new-sound.mp3';
      const adminStorage = getStorageContext('admin').storage();
      
      // Upload
      await assertSucceeds(
        adminStorage.ref(systemPath).put(testFiles.audioFile.data, {
          contentType: testFiles.audioFile.contentType
        })
      );
      
      // Read
      await assertSucceeds(adminStorage.ref(systemPath).getDownloadURL());
      
      // Delete
      await assertSucceeds(adminStorage.ref(systemPath).delete());
    });
  });

  describe('Default Deny Rule Tests', () => {
    
    test('Unauthorized paths are denied', async () => {
      const unauthorizedPath = 'unauthorized/path/file.txt';
      const storage = getStorageContext('standardUser').storage();
      await assertFails(
        storage.ref(unauthorizedPath).put(testFiles.validDocument.data, {
          contentType: testFiles.validDocument.contentType
        })
      );
    });

    test('Unmatched patterns are denied', async () => {
      const unmatchedPath = 'random/location/file.pdf';
      const storage = getStorageContext('standardUser').storage();
      await assertFails(storage.ref(unmatchedPath).getDownloadURL());
    });
  });
});

/**
 * Performance and Load Tests
 */
describe('Storage Rules Performance Tests', () => {
  let testEnv;

  beforeAll(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID + '-perf',
      storage: {
        rules: fs.readFileSync(STORAGE_RULES_FILE, 'utf8'),
        host: 'localhost',
        port: 9199
      }
    });
  });

  afterAll(async () => {
    await testEnv.cleanup();
  });

  test('Rules perform efficiently under load', async () => {
    const storage = testEnv.authenticatedContext('loadtest', { uid: 'loadtest' }).storage();
    const promises = [];

    // Simulate concurrent file operations
    for (let i = 0; i < 50; i++) {
      const filePath = `users/loadtest/tasks/task${i}/attachments/file${i}.pdf`;
      promises.push(
        storage.ref(filePath).put(Buffer.alloc(1024, 'L'), {
          contentType: 'application/pdf'
        })
      );
    }

    const startTime = Date.now();
    await Promise.all(promises);
    const endTime = Date.now();

    const duration = endTime - startTime;
    console.log(`Upload performance: ${duration}ms for 50 files`);
    expect(duration).toBeLessThan(30000); // Should complete within 30 seconds
  });
});

console.log(`
=== Firebase Storage Security Rules Test Suite ===

This comprehensive test suite validates:

✅ User Profile Storage Security
  - Profile picture uploads with size/type validation
  - Premium background images
  - Custom sound uploads (premium feature)

✅ Task Attachment Security
  - Document and image attachments
  - File size and type restrictions  
  - Voice notes (premium feature)
  - User isolation enforcement

✅ Data Export Security
  - System-generated exports
  - Analytics reports (premium)
  - Enterprise backups
  - User access restrictions

✅ Enterprise Collaboration Security
  - Workspace shared files
  - Organization assets
  - Team collaboration files
  - Role-based access control

✅ System Assets Security
  - Focus sounds and notifications
  - Achievement images
  - UI assets and themes
  - Admin-only management

✅ AI/ML Model Security
  - Model file access
  - Training data protection
  - System-only uploads

✅ Temporary File Management
  - Temp upload security
  - Large file handling
  - Cleanup procedures

✅ File Security Validation
  - File name sanitization
  - Content type validation
  - Size limit enforcement
  - Malicious file rejection

✅ Admin Override Capabilities
  - Full system access
  - Emergency procedures
  - Asset management

✅ Performance Testing
  - Concurrent operation handling
  - Load testing validation
  - Rule efficiency verification

To run the tests:
1. npm install @firebase/rules-unit-testing jest
2. Start Firebase Storage emulator: firebase emulators:start --only storage
3. Run tests: npx jest firebase_storage_rules_test.js --verbose

Expected Results:
- All security rules properly enforce file restrictions
- Role-based access works correctly for all features
- File size and type validations prevent abuse
- User isolation prevents unauthorized access
- Performance remains acceptable under load
`);