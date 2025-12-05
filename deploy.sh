#!/bin/bash

# Deployment Script for d1-rest Cloudflare Worker
# This script automates the deployment process with comprehensive logging

set -e  # Exit on error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="${LOG_DIR}/deployment_${TIMESTAMP}.log"
DEPLOYMENT_CONFIG="${SCRIPT_DIR}/deployment.config.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create logs directory if it doesn't exist
mkdir -p "${LOG_DIR}"

# Logging functions
log_info() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "${BLUE}[INFO]${NC} $*"
    echo "[${timestamp}] [INFO] $*" >> "${LOG_FILE}"
}

log_success() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "${GREEN}[SUCCESS]${NC} $*"
    echo "[${timestamp}] [SUCCESS] $*" >> "${LOG_FILE}"
}

log_warning() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "${YELLOW}[WARNING]${NC} $*"
    echo "[${timestamp}] [WARNING] $*" >> "${LOG_FILE}"
}

log_error() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "${RED}[ERROR]${NC} $*"
    echo "[${timestamp}] [ERROR] $*" >> "${LOG_FILE}"
}

# Print deployment header
print_header() {
    log_info "════════════════════════════════════════════════════════"
    log_info "  d1-rest Cloudflare Worker Deployment"
    log_info "  Timestamp: ${TIMESTAMP}"
    log_info "  Log File: ${LOG_FILE}"
    log_info "════════════════════════════════════════════════════════"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if wrangler is installed
    if ! command -v wrangler &> /dev/null; then
        log_error "wrangler CLI not found. Please install it first."
        exit 1
    fi
    log_success "wrangler CLI found: $(wrangler --version)"
    
    # Check if node is installed
    if ! command -v node &> /dev/null; then
        log_error "node not found. Please install Node.js first."
        exit 1
    fi
    log_success "Node.js found: $(node --version)"
    
    # Check if npm is installed
    if ! command -v npm &> /dev/null; then
        log_error "npm not found. Please install npm first."
        exit 1
    fi
    log_success "npm found: $(npm --version)"
    
    # Check if wrangler.jsonc exists
    if [ ! -f "${SCRIPT_DIR}/wrangler.jsonc" ]; then
        log_error "wrangler.jsonc not found in ${SCRIPT_DIR}"
        exit 1
    fi
    log_success "wrangler.jsonc found"
}

# Install dependencies
install_dependencies() {
    log_info "Installing dependencies..."
    cd "${SCRIPT_DIR}"
    
    if npm install >> "${LOG_FILE}" 2>&1; then
        log_success "Dependencies installed successfully"
    else
        log_error "Failed to install dependencies"
        exit 1
    fi
}

# Run type checking (if applicable)
run_type_check() {
    log_info "Running type check..."
    cd "${SCRIPT_DIR}"
    
    if npx tsc --noEmit >> "${LOG_FILE}" 2>&1; then
        log_success "Type check passed"
    else
        log_warning "Type check failed or not configured"
    fi
}

# Deploy to Cloudflare
deploy_to_cloudflare() {
    log_info "Deploying to Cloudflare Workers..."
    cd "${SCRIPT_DIR}"
    
    if wrangler deploy >> "${LOG_FILE}" 2>&1; then
        log_success "Deployment to Cloudflare successful!"
    else
        log_error "Deployment failed. Check logs for details."
        exit 1
    fi
}

# Save deployment metadata
save_deployment_metadata() {
    log_info "Saving deployment metadata..."
    
    local metadata_file="${LOG_DIR}/deployment_metadata_${TIMESTAMP}.json"
    
    cat > "${metadata_file}" <<EOF
{
  "timestamp": "${TIMESTAMP}",
  "deployment_date": "$(date -Iseconds)",
  "git_commit": "$(git rev-parse HEAD 2>/dev/null || echo 'N/A')",
  "git_branch": "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'N/A')",
  "deployer": "${USER}",
  "log_file": "${LOG_FILE}",
  "status": "success"
}
EOF
    
    log_success "Deployment metadata saved to ${metadata_file}"
}

# Print deployment summary
print_summary() {
    log_info "════════════════════════════════════════════════════════"
    log_success "Deployment completed successfully!"
    log_info "Summary:"
    log_info "  - Timestamp: ${TIMESTAMP}"
    log_info "  - Log file: ${LOG_FILE}"
    log_info "  - Git commit: $(git rev-parse --short HEAD 2>/dev/null || echo 'N/A')"
    log_info "  - Git branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'N/A')"
    log_info "════════════════════════════════════════════════════════"
}

# Main deployment flow
main() {
    print_header
    check_prerequisites
    install_dependencies
    run_type_check
    deploy_to_cloudflare
    save_deployment_metadata
    print_summary
}

# Error handler
trap 'log_error "Deployment failed at line $LINENO. Check ${LOG_FILE} for details."; exit 1' ERR

# Run main function
main
