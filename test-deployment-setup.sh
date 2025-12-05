#!/bin/bash

# Deployment Test Script (Simulation)
# This script simulates the deployment process to verify the workflow

set -e

echo "🧪 Testing Deployment and Backup Scripts"
echo "========================================"
echo ""

# Test 1: Check script syntax
echo "Test 1: Validating script syntax..."
if bash -n deploy.sh && bash -n backup.sh; then
    echo "✅ Scripts are syntactically correct"
else
    echo "❌ Script syntax validation failed"
    exit 1
fi
echo ""

# Test 2: Check script permissions
echo "Test 2: Checking script permissions..."
if [ -x deploy.sh ] && [ -x backup.sh ]; then
    echo "✅ Scripts are executable"
else
    echo "❌ Scripts are not executable"
    echo "Run: chmod +x deploy.sh backup.sh"
    exit 1
fi
echo ""

# Test 3: Verify configuration files exist
echo "Test 3: Checking configuration files..."
if [ -f deployment.config.json ] && [ -f backup.config.json ]; then
    echo "✅ Configuration files found"
else
    echo "❌ Configuration files missing"
    exit 1
fi
echo ""

# Test 4: Validate JSON configuration
echo "Test 4: Validating JSON configuration..."
if command -v jq &> /dev/null; then
    if jq empty deployment.config.json backup.config.json 2>/dev/null; then
        echo "✅ JSON configuration is valid"
    else
        echo "❌ JSON configuration is invalid"
        exit 1
    fi
else
    echo "⚠️  jq not found, skipping JSON validation"
fi
echo ""

# Test 5: Check required commands
echo "Test 5: Checking required commands..."
missing_cmds=()

if ! command -v node &> /dev/null; then
    missing_cmds+=("node")
fi

if ! command -v npm &> /dev/null; then
    missing_cmds+=("npm")
fi

if ! command -v rsync &> /dev/null; then
    missing_cmds+=("rsync")
fi

if [ ${#missing_cmds[@]} -eq 0 ]; then
    echo "✅ All required commands found"
    echo "   - node: $(node --version)"
    echo "   - npm: $(npm --version)"
    echo "   - rsync: $(rsync --version | head -n 1)"
else
    echo "⚠️  Some commands are missing: ${missing_cmds[*]}"
    echo "   Note: wrangler will be needed for actual deployment"
fi
echo ""

# Test 6: Verify npm scripts
echo "Test 6: Checking npm scripts..."
if grep -q "deploy:full" package.json && \
   grep -q "backup" package.json && \
   grep -q "deploy:with-backup" package.json; then
    echo "✅ NPM scripts configured correctly"
    echo "   Available commands:"
    echo "   - npm run deploy"
    echo "   - npm run deploy:full"
    echo "   - npm run backup"
    echo "   - npm run deploy:with-backup"
else
    echo "❌ NPM scripts not properly configured"
    exit 1
fi
echo ""

# Test 7: Create test log directory
echo "Test 7: Testing log directory creation..."
mkdir -p logs
if [ -d logs ]; then
    echo "✅ Logs directory created successfully"
else
    echo "❌ Failed to create logs directory"
    exit 1
fi
echo ""

# Test 8: Documentation check
echo "Test 8: Checking documentation..."
if [ -f DEPLOYMENT.md ] && [ -f QUICKSTART.md ]; then
    echo "✅ Documentation files found"
    echo "   - DEPLOYMENT.md ($(wc -l < DEPLOYMENT.md) lines)"
    echo "   - QUICKSTART.md ($(wc -l < QUICKSTART.md) lines)"
else
    echo "❌ Documentation files missing"
    exit 1
fi
echo ""

# Summary
echo "========================================"
echo "🎉 All tests passed!"
echo ""
echo "Next Steps:"
echo "1. Review the deployment documentation: cat DEPLOYMENT.md"
echo "2. Configure Cloudflare authentication: wrangler login"
echo "3. Test locally: npm run dev"
echo "4. Create a backup: npm run backup"
echo "5. Deploy to production: npm run deploy:full"
echo ""
echo "For more information, see DEPLOYMENT.md and QUICKSTART.md"
