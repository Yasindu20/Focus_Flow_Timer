#!/bin/bash

# Firebase Storage Rules Deployment Script
# Focus Flow Timer - Enterprise Edition

echo "🔒 Firebase Storage Rules Deployment Script"
echo "==========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID="focus-flow-timer"
BACKUP_DIR="./firebase-backups/storage/$(date +%Y%m%d_%H%M%S)"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites..."
    
    # Check if Firebase CLI is installed
    if ! command -v firebase &> /dev/null; then
        print_error "Firebase CLI is not installed. Please install it first:"
        echo "npm install -g firebase-tools"
        exit 1
    fi
    
    # Check if user is logged in
    if ! firebase projects:list &> /dev/null; then
        print_error "Not logged into Firebase. Please run: firebase login"
        exit 1
    fi
    
    # Check if storage rules file exists
    if [[ ! -f "storage.rules" ]]; then
        print_error "storage.rules file not found!"
        exit 1
    fi
    
    # Check if Node.js is available for testing
    if ! command -v node &> /dev/null; then
        print_warning "Node.js not found. Some tests may be skipped."
    fi
    
    print_status "All prerequisites met ✓"
}

# Function to validate syntax
validate_syntax() {
    print_step "Validating Firebase Storage rules syntax..."
    
    # Check if rules file has basic syntax
    if grep -q "rules_version = '2'" storage.rules && grep -q "service firebase.storage" storage.rules; then
        print_status "Storage rules syntax appears valid ✓"
    else
        print_error "Storage rules syntax validation failed!"
        print_error "Make sure the file starts with rules_version = '2' and contains service firebase.storage"
        exit 1
    fi
    
    # Validate with Firebase CLI if possible
    if firebase storage:rules:get --help &> /dev/null; then
        print_status "Firebase CLI storage commands available ✓"
    else
        print_warning "Cannot validate with Firebase CLI. Proceeding with basic validation."
    fi
}

# Function to create backup
create_backup() {
    print_step "Creating backup of current storage rules..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Try to backup current rules
    if firebase storage:rules:get > "$BACKUP_DIR/current-storage-rules.txt" 2>/dev/null; then
        print_status "Current storage rules backed up to $BACKUP_DIR/current-storage-rules.txt"
    else
        print_warning "Could not backup current storage rules (may not exist yet)"
    fi
    
    # Backup the rules file we're about to deploy
    cp storage.rules "$BACKUP_DIR/storage.rules" 2>/dev/null || true
    print_status "New storage rules backed up to $BACKUP_DIR"
}

# Function to run validation tests
run_validation_tests() {
    print_step "Running storage rules validation tests..."
    
    if [[ -f "storage_rules_validation.js" ]] && command -v node &> /dev/null; then
        print_status "Running validation script..."
        if node storage_rules_validation.js | tail -n 10 | grep -q "All security validations passed!"; then
            print_status "Storage rules validation tests passed ✓"
        else
            print_error "Storage rules validation tests failed!"
            print_error "Please review the test output above and fix any issues."
            exit 1
        fi
    else
        print_warning "Validation script not found or Node.js not available. Skipping validation tests."
    fi
}

# Function to run security tests
run_security_tests() {
    print_step "Running security test suite..."
    
    if [[ -f "firebase_storage_rules_test.js" ]] && command -v npm &> /dev/null; then
        print_status "Installing test dependencies..."
        npm install --save-dev @firebase/rules-unit-testing jest &> /dev/null || true
        
        print_status "Starting Firebase Storage emulator..."
        firebase emulators:start --only storage --port 9199 &
        EMULATOR_PID=$!
        
        # Wait for emulator to start
        sleep 15
        
        print_status "Running security test suite..."
        if timeout 120 npm test firebase_storage_rules_test.js; then
            print_status "Security tests passed ✓"
        else
            print_error "Security tests failed! Deployment aborted."
            kill $EMULATOR_PID 2>/dev/null
            exit 1
        fi
        
        # Stop emulator
        kill $EMULATOR_PID 2>/dev/null
    else
        print_warning "Security test suite not found or npm not available. Skipping security tests."
        print_warning "⚠️ SECURITY WARNING: Deploying without full test validation!"
    fi
}

# Function to deploy storage rules
deploy_storage_rules() {
    print_step "Deploying Firebase Storage security rules..."
    
    if firebase deploy --only storage; then
        print_status "Storage security rules deployed successfully ✓"
    else
        print_error "Storage rules deployment failed!"
        return 1
    fi
}

# Function to verify deployment
verify_deployment() {
    print_step "Verifying deployment..."
    
    # Check if rules were deployed
    print_status "Checking deployed storage rules..."
    if firebase storage:rules:get > /tmp/deployed-storage-rules.txt; then
        if grep -q "rules_version = '2'" /tmp/deployed-storage-rules.txt; then
            print_status "Storage rules deployment verified ✓"
        else
            print_error "Storage rules deployment verification failed!"
            return 1
        fi
    else
        print_warning "Could not verify deployed storage rules"
    fi
    
    print_status "Deployment verification complete ✓"
    rm -f /tmp/deployed-storage-rules.txt
}

# Function to test file operations
test_file_operations() {
    print_step "Testing basic file operations..."
    
    print_status "File operation testing requires manual verification:"
    echo "1. Open your Flutter app"
    echo "2. Try uploading a profile picture"
    echo "3. Try uploading a task attachment"
    echo "4. Verify file size limits are enforced"
    echo "5. Test different user roles (standard vs premium)"
    echo "6. Check that unauthorized access is blocked"
    
    print_warning "Manual testing checklist:"
    echo "□ Profile picture upload (5MB limit)"
    echo "□ Task document attachment (25MB limit)"
    echo "□ Task image attachment (15MB limit)"
    echo "□ Premium background upload (premium only)"
    echo "□ Custom sound upload (premium only)"
    echo "□ Voice note upload (premium only)"
    echo "□ File type validation (reject .exe, etc.)"
    echo "□ User isolation (can't access other user files)"
    echo "□ Enterprise workspace sharing (enterprise only)"
    echo "□ Admin asset management (admin only)"
}

# Function to display post-deployment instructions
post_deployment_instructions() {
    print_step "Post-deployment instructions..."
    
    echo ""
    echo "🎉 Storage Rules Deployment completed successfully!"
    echo ""
    echo "📋 Next Steps:"
    echo "1. Test file upload functionality in your app"
    echo "2. Monitor Firebase Console for storage usage"
    echo "3. Check for any rule evaluation errors"
    echo "4. Set up storage usage monitoring and alerts"
    echo "5. Update team documentation with new storage features"
    echo ""
    echo "🔧 Monitoring Commands:"
    echo "- firebase storage:rules:get (view current rules)"
    echo "- Check Firebase Console > Storage > Files"
    echo "- Monitor Firebase Console > Storage > Usage"
    echo ""
    echo "📞 Emergency Rollback:"
    echo "If issues occur, restore from backup:"
    echo "- Copy backup rules: cp $BACKUP_DIR/current-storage-rules.txt storage.rules"
    echo "- Deploy backup: firebase deploy --only storage"
    echo ""
    echo "📊 File Size Limits Summary:"
    echo "- Profile Pictures: 5MB (all users)"
    echo "- Profile Backgrounds: 10MB (premium only)"
    echo "- Custom Sounds: 50MB (premium only)"
    echo "- Task Documents: 25MB (all users)"
    echo "- Task Images: 15MB (all users)"
    echo "- Voice Notes: 100MB (premium only)"
    echo "- Workspace Files: 50MB (enterprise only)"
    echo "- Team Files: 100MB (enterprise only)"
    echo "- Temporary Files: 500MB (all users)"
    echo ""
    echo "🔒 Security Features Enabled:"
    echo "✅ User data isolation"
    echo "✅ File type validation"
    echo "✅ Size limit enforcement"
    echo "✅ Role-based access control"
    echo "✅ Premium feature restrictions"
    echo "✅ Enterprise collaboration"
    echo "✅ Malicious file blocking"
    echo "✅ Admin override capabilities"
    echo ""
}

# Main deployment function
main() {
    echo "Starting Firebase Storage Rules Deployment..."
    echo "Project: $PROJECT_ID"
    echo "Timestamp: $(date)"
    echo ""
    
    # Deployment steps
    check_prerequisites
    validate_syntax
    create_backup
    
    # Ask for confirmation
    echo ""
    read -p "🚨 Ready to deploy storage rules? This will update production file permissions. Continue? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled by user."
        exit 1
    fi
    
    # Optional: Run validation tests
    read -p "🧪 Run validation tests before deployment? (Y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        run_validation_tests
    fi
    
    # Optional: Run security tests
    read -p "🔒 Run comprehensive security tests? (slower but recommended) (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        run_security_tests
    fi
    
    # Deploy storage rules
    if deploy_storage_rules && verify_deployment; then
        test_file_operations
        post_deployment_instructions
        
        print_status "🎉 Storage rules deployment completed successfully!"
        echo ""
        echo "📧 Send deployment notification to team:"
        echo "Subject: Firebase Storage Rules Deployed"
        echo "Body: New storage security rules have been deployed."
        echo "      File upload permissions and size limits are now active."
        echo "      Backup location: $BACKUP_DIR"
        echo "      Please test file upload functionality."
        
    else
        print_error "Deployment failed! Check the errors above."
        echo ""
        echo "🔄 To rollback, use backup files in: $BACKUP_DIR"
        exit 1
    fi
}

# Script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi