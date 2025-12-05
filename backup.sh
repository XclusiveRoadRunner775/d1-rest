#!/bin/bash

# Backup Script for d1-rest Repository
# This script automates repository backup to a remote location (iCloud or other)

set -e  # Exit on error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="${LOG_DIR}/backup_${TIMESTAMP}.log"
BACKUP_CONFIG="${SCRIPT_DIR}/backup.config.json"

# Default backup location (can be overridden via config or environment variable)
BACKUP_LOCATION="${BACKUP_LOCATION:-$HOME/Library/Mobile Documents/com~apple~CloudDocs/d1-rest-backups}"

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
    echo -e "${BLUE}[INFO]${NC} $*" | tee -a "${LOG_FILE}"
    echo "[${timestamp}] [INFO] $*" >> "${LOG_FILE}"
}

log_success() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "${GREEN}[SUCCESS]${NC} $*" | tee -a "${LOG_FILE}"
    echo "[${timestamp}] [SUCCESS] $*" >> "${LOG_FILE}"
}

log_warning() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "${YELLOW}[WARNING]${NC} $*" | tee -a "${LOG_FILE}"
    echo "[${timestamp}] [WARNING] $*" >> "${LOG_FILE}"
}

log_error() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "${LOG_FILE}"
    echo "[${timestamp}] [ERROR] $*" >> "${LOG_FILE}"
}

# Print backup header
print_header() {
    log_info "════════════════════════════════════════════════════════"
    log_info "  d1-rest Repository Backup"
    log_info "  Timestamp: ${TIMESTAMP}"
    log_info "  Log File: ${LOG_FILE}"
    log_info "════════════════════════════════════════════════════════"
}

# Load configuration from backup.config.json if it exists
load_config() {
    if [ -f "${BACKUP_CONFIG}" ]; then
        log_info "Loading backup configuration from ${BACKUP_CONFIG}"
        
        # Extract backup location from JSON config (requires jq or manual parsing)
        if command -v jq &> /dev/null; then
            local config_location=$(jq -r '.backup_location // empty' "${BACKUP_CONFIG}")
            if [ -n "${config_location}" ]; then
                BACKUP_LOCATION="${config_location}"
                log_info "Backup location from config: ${BACKUP_LOCATION}"
            fi
        else
            log_warning "jq not found, using default backup location"
        fi
    else
        log_info "No backup configuration found, using default settings"
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if rsync is available
    if ! command -v rsync &> /dev/null; then
        log_error "rsync not found. Please install rsync first."
        exit 1
    fi
    log_success "rsync found: $(rsync --version | head -n 1)"
    
    # Check if git is available
    if ! command -v git &> /dev/null; then
        log_warning "git not found. Version control info will be limited."
    else
        log_success "git found: $(git --version)"
    fi
}

# Create backup directory structure
create_backup_structure() {
    log_info "Creating backup directory structure..."
    
    local backup_dir="${BACKUP_LOCATION}/${TIMESTAMP}"
    
    if mkdir -p "${backup_dir}"; then
        log_success "Backup directory created: ${backup_dir}"
        echo "${backup_dir}"
    else
        log_error "Failed to create backup directory: ${backup_dir}"
        exit 1
    fi
}

# Perform backup using rsync
perform_backup() {
    local backup_dir="$1"
    
    log_info "Starting backup to ${backup_dir}..."
    
    # Rsync options:
    # -a: archive mode (preserves permissions, timestamps, etc.)
    # -v: verbose
    # -h: human-readable
    # --delete: delete files in destination that don't exist in source
    # --exclude: exclude certain directories/files
    
    if rsync -avh \
        --exclude 'node_modules' \
        --exclude '.git' \
        --exclude 'logs' \
        --exclude '*.log' \
        --exclude '.DS_Store' \
        --exclude 'dist' \
        "${SCRIPT_DIR}/" "${backup_dir}/" >> "${LOG_FILE}" 2>&1; then
        log_success "Backup completed successfully"
    else
        log_error "Backup failed"
        exit 1
    fi
    
    # Calculate backup size
    local backup_size=$(du -sh "${backup_dir}" | cut -f1)
    log_info "Backup size: ${backup_size}"
}

# Save git metadata
save_git_metadata() {
    local backup_dir="$1"
    
    log_info "Saving git metadata..."
    
    cd "${SCRIPT_DIR}"
    
    if command -v git &> /dev/null && git rev-parse --git-dir > /dev/null 2>&1; then
        local metadata_file="${backup_dir}/git_metadata.json"
        
        cat > "${metadata_file}" <<EOF
{
  "commit": "$(git rev-parse HEAD)",
  "short_commit": "$(git rev-parse --short HEAD)",
  "branch": "$(git rev-parse --abbrev-ref HEAD)",
  "remote": "$(git config --get remote.origin.url || echo 'N/A')",
  "author": "$(git log -1 --pretty=format:'%an <%ae>')",
  "commit_date": "$(git log -1 --pretty=format:'%ci')",
  "commit_message": "$(git log -1 --pretty=format:'%s')",
  "backup_timestamp": "${TIMESTAMP}"
}
EOF
        
        log_success "Git metadata saved to ${metadata_file}"
    else
        log_warning "Not a git repository or git not available, skipping git metadata"
    fi
}

# Create backup manifest
create_backup_manifest() {
    local backup_dir="$1"
    
    log_info "Creating backup manifest..."
    
    local manifest_file="${backup_dir}/backup_manifest.json"
    local file_count=$(find "${backup_dir}" -type f | wc -l)
    local dir_count=$(find "${backup_dir}" -type d | wc -l)
    
    cat > "${manifest_file}" <<EOF
{
  "backup_timestamp": "${TIMESTAMP}",
  "backup_date": "$(date -Iseconds)",
  "source_directory": "${SCRIPT_DIR}",
  "backup_directory": "${backup_dir}",
  "file_count": ${file_count},
  "directory_count": ${dir_count},
  "backup_size": "$(du -sh "${backup_dir}" | cut -f1)",
  "operator": "${USER}",
  "hostname": "$(hostname)",
  "log_file": "${LOG_FILE}"
}
EOF
    
    log_success "Backup manifest created at ${manifest_file}"
}

# Maintain backup rotation (keep only last N backups)
maintain_backup_rotation() {
    local keep_count="${BACKUP_KEEP_COUNT:-10}"
    
    log_info "Maintaining backup rotation (keeping last ${keep_count} backups)..."
    
    if [ -d "${BACKUP_LOCATION}" ]; then
        local backup_count=$(find "${BACKUP_LOCATION}" -maxdepth 1 -type d -name "202*" | wc -l)
        
        if [ "${backup_count}" -gt "${keep_count}" ]; then
            log_info "Found ${backup_count} backups, removing oldest ones..."
            
            # Get oldest backups to remove
            find "${BACKUP_LOCATION}" -maxdepth 1 -type d -name "202*" | sort | head -n -${keep_count} | while read old_backup; do
                log_info "Removing old backup: ${old_backup}"
                rm -rf "${old_backup}"
            done
            
            log_success "Backup rotation completed"
        else
            log_info "Backup count (${backup_count}) within limit (${keep_count}), no rotation needed"
        fi
    fi
}

# Create symbolic link to latest backup
create_latest_link() {
    local backup_dir="$1"
    local latest_link="${BACKUP_LOCATION}/latest"
    
    log_info "Creating symbolic link to latest backup..."
    
    # Remove old link if it exists
    if [ -L "${latest_link}" ]; then
        rm -f "${latest_link}"
    fi
    
    # Create new link
    if ln -s "${backup_dir}" "${latest_link}"; then
        log_success "Latest backup link created: ${latest_link}"
    else
        log_warning "Failed to create latest backup link"
    fi
}

# Print backup summary
print_summary() {
    local backup_dir="$1"
    
    log_info "════════════════════════════════════════════════════════"
    log_success "Backup completed successfully!"
    log_info "Summary:"
    log_info "  - Timestamp: ${TIMESTAMP}"
    log_info "  - Backup location: ${backup_dir}"
    log_info "  - Log file: ${LOG_FILE}"
    log_info "  - Git commit: $(git rev-parse --short HEAD 2>/dev/null || echo 'N/A')"
    log_info "════════════════════════════════════════════════════════"
}

# Main backup flow
main() {
    print_header
    load_config
    check_prerequisites
    
    local backup_dir=$(create_backup_structure)
    
    perform_backup "${backup_dir}"
    save_git_metadata "${backup_dir}"
    create_backup_manifest "${backup_dir}"
    maintain_backup_rotation
    create_latest_link "${backup_dir}"
    print_summary "${backup_dir}"
}

# Error handler
trap 'log_error "Backup failed at line $LINENO. Check ${LOG_FILE} for details."; exit 1' ERR

# Run main function
main
