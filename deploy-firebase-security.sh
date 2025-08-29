#!/bin/bash

# Firebase Security Rules and Indexes Deployment Script
# Focus Flow Timer - Enterprise Edition

echo "🚀 Firebase Security Deployment Script"
echo "======================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID="focus-flow-timer"
BACKUP_DIR="./firebase-backups/$(date +%Y%m%d_%H%M%S)"

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
    
    # Check if required files exist
    if [[ ! -f "firestore.rules" ]]; then
        print_error "firestore.rules file not found!"
        exit 1
    fi
    
    if [[ ! -f "firestore.indexes.json" ]]; then
        print_error "firestore.indexes.json file not found!"
        exit 1
    fi
    
    print_status "All prerequisites met ✓"
}

# Function to validate syntax
validate_syntax() {
    print_step "Validating Firebase configuration syntax..."
    
    # Validate Firestore rules syntax
    if firebase firestore:rules:check firestore.rules; then
        print_status "Firestore rules syntax is valid ✓"
    else
        print_error "Firestore rules syntax validation failed!"
        exit 1
    fi
    
    # Validate indexes JSON
    if python3 -m json.tool firestore.indexes.json > /dev/null 2>&1; then
        print_status "Firestore indexes JSON is valid ✓"
    else
        print_error "Firestore indexes JSON validation failed!"
        exit 1
    fi
}

# Function to create backup
create_backup() {
    print_step "Creating backup of current configuration..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup current rules if they exist
    if firebase firestore:rules:get > "$BACKUP_DIR/current-rules.txt" 2>/dev/null; then
        print_status "Current rules backed up to $BACKUP_DIR/current-rules.txt"
    else
        print_warning "Could not backup current rules (may not exist)"
    fi
    
    # Backup current indexes
    cp firestore.indexes.json "$BACKUP_DIR/firestore.indexes.json" 2>/dev/null || true
    print_status "Configuration backed up to $BACKUP_DIR"
}

# Function to run tests
run_tests() {
    print_step "Running security tests..."
    
    if [[ -f "firebase_rules_test.js" ]] && command -v npm &> /dev/null; then
        print_status "Installing test dependencies..."
        npm install --save-dev @firebase/rules-unit-testing jest
        
        print_status "Starting Firebase emulators..."
        firebase emulators:start --only firestore --port 8080 &
        EMULATOR_PID=$!
        
        # Wait for emulator to start
        sleep 10
        
        print_status "Running test suite..."
        if npm test firebase_rules_test.js; then
            print_status "All tests passed ✓"
        else
            print_error "Tests failed! Deployment aborted."
            kill $EMULATOR_PID 2>/dev/null
            exit 1
        fi
        
        # Stop emulator
        kill $EMULATOR_PID 2>/dev/null
    else
        print_warning "Test suite not found or npm not available. Skipping tests."
    fi
}

# Function to deploy indexes
deploy_indexes() {
    print_step "Deploying Firestore indexes..."
    
    if firebase deploy --only firestore:indexes; then
        print_status "Indexes deployed successfully ✓"
        print_warning "Index deployment may take several minutes to complete in the Firebase Console"
    else
        print_error "Index deployment failed!"
        return 1
    fi
}

# Function to deploy rules
deploy_rules() {
    print_step "Deploying Firestore security rules..."
    
    if firebase deploy --only firestore:rules; then
        print_status "Security rules deployed successfully ✓"
    else
        print_error "Security rules deployment failed!"
        return 1
    fi
}

# Function to verify deployment
verify_deployment() {
    print_step "Verifying deployment..."
    
    # Check if rules were deployed
    print_status "Checking deployed rules..."
    firebase firestore:rules:get > /tmp/deployed-rules.txt
    if grep -q "rules_version = '2'" /tmp/deployed-rules.txt; then
        print_status "Rules deployment verified ✓"
    else
        print_error "Rules deployment verification failed!"
        return 1
    fi
    
    # List indexes
    print_status "Current indexes:"
    firebase firestore:indexes
    
    print_status "Deployment verification complete ✓"
    rm -f /tmp/deployed-rules.txt
}

# Function to run performance tests
run_performance_tests() {
    print_step "Running performance validation..."
    
    print_status "Performance testing requires manual verification in Firebase Console:"
    echo "1. Go to Firebase Console > Firestore > Usage tab"
    echo "2. Monitor index usage and query performance"
    echo "3. Check for any missing index warnings"
    echo "4. Verify read/write operation efficiency"
    
    print_warning "Set up monitoring alerts for:"
    echo "- High query execution times"
    echo "- Missing index warnings"
    echo "- Unusual read/write patterns"
    echo "- Error rate spikes"
}

# Function to display post-deployment instructions
post_deployment_instructions() {
    print_step "Post-deployment instructions..."
    
    echo ""
    echo "🎉 Deployment completed successfully!"
    echo ""
    echo "📋 Next Steps:"
    echo "1. Monitor Firebase Console for index build completion"
    echo "2. Test application functionality thoroughly"
    echo "3. Monitor performance metrics and error rates"
    echo "4. Set up automated monitoring and alerting"
    echo "5. Update team documentation with new security model"
    echo ""
    echo "🔧 Monitoring Commands:"
    echo "- firebase firestore:indexes (check index status)"
    echo "- firebase firestore:rules:get (view current rules)"
    echo ""
    echo "📞 Emergency Rollback:"
    echo "If issues occur, restore from backup:"
    echo "- Rules: firebase deploy --only firestore:rules"
    echo "- Indexes: firebase deploy --only firestore:indexes"
    echo "- Backup location: $BACKUP_DIR"
    echo ""
    echo "📊 Performance Monitoring:"
    echo "- Firebase Console > Firestore > Usage"
    echo "- Cloud Monitoring > Firebase metrics"
    echo "- Application logs for security events"
    echo ""
}

# Main deployment function
main() {
    echo "Starting Firebase Security Deployment..."
    echo "Project: $PROJECT_ID"
    echo "Timestamp: $(date)"
    echo ""
    
    # Deployment steps
    check_prerequisites
    validate_syntax
    create_backup
    
    # Ask for confirmation
    echo ""
    read -p "🚨 Ready to deploy? This will update production security rules and indexes. Continue? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled by user."
        exit 1
    fi
    
    # Optional: Run tests
    read -p "🧪 Run security tests before deployment? (Y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        run_tests
    fi
    
    # Deploy components
    if deploy_indexes && deploy_rules; then
        verify_deployment
        run_performance_tests
        post_deployment_instructions
        
        print_status "🎉 All deployment steps completed successfully!"
        echo ""
        echo "📧 Send deployment notification to team:"
        echo "Subject: Firebase Security Rules & Indexes Deployed"
        echo "Body: Security rules and database indexes have been updated."
        echo "      Please monitor application performance and report any issues."
        echo "      Backup location: $BACKUP_DIR"
        
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