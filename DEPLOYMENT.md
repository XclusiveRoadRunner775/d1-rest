# Deployment and Backup Guide

This guide provides comprehensive instructions for deploying the d1-rest Cloudflare Worker and managing automated backups.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Deployment](#deployment)
- [Backup](#backup)
- [Configuration](#configuration)
- [Logging](#logging)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Before deploying or backing up, ensure you have:

1. **Node.js and npm** installed (v16 or higher recommended)
2. **Wrangler CLI** installed and configured with Cloudflare credentials
3. **rsync** installed (for backups, usually pre-installed on macOS/Linux)
4. **Git** (optional, for version control metadata)

### Installing Prerequisites

```bash
# Install Node.js (if not already installed)
# Visit https://nodejs.org/ or use a package manager

# Install Wrangler globally
npm install -g wrangler

# Login to Cloudflare
wrangler login

# Verify installations
node --version
npm --version
wrangler --version
rsync --version
```

## Quick Start

### Deploy to Cloudflare

```bash
# Simple deployment (existing method)
npm run deploy

# Full deployment with logging and validation
npm run deploy:full

# Backup and deploy in one command
npm run deploy:with-backup
```

### Create a Backup

```bash
# Run backup script
npm run backup
```

## Deployment

### Deployment Methods

#### 1. Basic Deployment

The simplest way to deploy:

```bash
npm run deploy
```

This runs `wrangler deploy` directly.

#### 2. Full Deployment (Recommended)

For production deployments with comprehensive logging:

```bash
npm run deploy:full
```

This script performs:
- ✅ Prerequisites check (wrangler, node, npm)
- ✅ Dependency installation
- ✅ TypeScript type checking
- ✅ Deployment to Cloudflare
- ✅ Deployment metadata logging
- ✅ Comprehensive deployment logs

#### 3. Deployment with Backup

To automatically backup before deploying:

```bash
npm run deploy:with-backup
```

This runs the backup script first, then deploys.

### Manual Deployment Script

You can also run the deployment script directly:

```bash
./deploy.sh
```

### What Happens During Deployment

1. **Prerequisites Check**: Verifies all required tools are installed
2. **Dependency Installation**: Ensures all npm packages are up to date
3. **Type Checking**: Validates TypeScript types (if applicable)
4. **Cloudflare Deployment**: Deploys the worker using wrangler
5. **Metadata Logging**: Saves deployment information and git metadata
6. **Summary**: Displays deployment summary with key information

### Deployment Logs

All deployment actions are logged to:

```
logs/deployment_YYYYMMDD_HHMMSS.log
```

Deployment metadata is saved to:

```
logs/deployment_metadata_YYYYMMDD_HHMMSS.json
```

## Backup

### Backup Overview

The backup system automatically syncs your repository to a remote location (iCloud by default) with the following features:

- 📦 Full repository backup with rsync
- 🔄 Automatic backup rotation (keeps last 10 backups by default)
- 📊 Backup manifests and git metadata
- 📝 Comprehensive logging
- 🔗 Symbolic link to latest backup

### Running a Backup

```bash
# Using npm script
npm run backup

# Or directly
./backup.sh
```

### Default Backup Location

By default, backups are saved to:

```
$HOME/Library/Mobile Documents/com~apple~CloudDocs/d1-rest-backups/
```

This is the iCloud Drive path on macOS.

### Customizing Backup Location

You can customize the backup location in two ways:

#### 1. Environment Variable

```bash
BACKUP_LOCATION="/path/to/backup/location" npm run backup
```

#### 2. Configuration File

Edit `backup.config.json`:

```json
{
  "backup": {
    "backup_location": "/custom/path/to/backups",
    ...
  }
}
```

### Backup Structure

Each backup creates a timestamped directory:

```
d1-rest-backups/
├── 20251205_093000/          # Backup directory (timestamped)
│   ├── src/                  # Source files
│   ├── package.json          # Package configuration
│   ├── wrangler.jsonc        # Wrangler configuration
│   ├── git_metadata.json     # Git information
│   └── backup_manifest.json  # Backup metadata
├── 20251205_153000/          # Another backup
└── latest/                   # Symlink to most recent backup
```

### Backup Rotation

By default, the system keeps the last 10 backups. Older backups are automatically removed.

To change this, set the environment variable:

```bash
BACKUP_KEEP_COUNT=20 npm run backup
```

Or edit `backup.config.json`:

```json
{
  "backup": {
    "keep_count": 20
  }
}
```

### What Gets Backed Up

The backup includes:
- All source code files
- Configuration files (package.json, wrangler.jsonc, tsconfig.json)
- Documentation (README.md, etc.)
- Deployment and backup scripts

The backup **excludes**:
- `node_modules/` (dependencies)
- `.git/` (git repository data)
- `logs/` (log files)
- `dist/` (build artifacts)
- `.DS_Store` and other system files

## Configuration

### Deployment Configuration

Edit `deployment.config.json` to customize deployment behavior:

```json
{
  "deployment": {
    "environment": "production",
    "auto_backup_before_deploy": true,
    "run_type_check": true,
    "notifications": {
      "enabled": false,
      "email": "",
      "slack_webhook": ""
    }
  },
  "wrangler": {
    "config_file": "wrangler.jsonc"
  },
  "logging": {
    "log_directory": "logs",
    "keep_logs_days": 30,
    "verbose": true
  }
}
```

### Backup Configuration

Edit `backup.config.json` to customize backup behavior:

```json
{
  "backup": {
    "enabled": true,
    "backup_location": "$HOME/Library/Mobile Documents/com~apple~CloudDocs/d1-rest-backups",
    "keep_count": 10,
    "exclude_patterns": [
      "node_modules",
      ".git",
      "logs",
      "*.log",
      ".DS_Store",
      "dist"
    ]
  },
  "schedule": {
    "auto_backup_on_deploy": true,
    "periodic_backup": false,
    "backup_interval_hours": 24
  }
}
```

## Logging

### Log Files

All scripts generate detailed logs in the `logs/` directory:

#### Deployment Logs

```
logs/deployment_YYYYMMDD_HHMMSS.log              # Detailed deployment log
logs/deployment_metadata_YYYYMMDD_HHMMSS.json    # Deployment metadata
```

#### Backup Logs

```
logs/backup_YYYYMMDD_HHMMSS.log                  # Detailed backup log
```

### Log Format

Logs include:
- Timestamp for each action
- Log level (INFO, SUCCESS, WARNING, ERROR)
- Detailed action descriptions
- Error messages and stack traces (if applicable)

### Viewing Logs

```bash
# View latest deployment log
ls -t logs/deployment_*.log | head -1 | xargs cat

# View latest backup log
ls -t logs/backup_*.log | head -1 | xargs cat

# Follow deployment log in real-time (in another terminal)
tail -f logs/deployment_*.log
```

## Troubleshooting

### Common Issues

#### 1. Permission Denied

**Problem**: `Permission denied` when running scripts

**Solution**:
```bash
chmod +x deploy.sh backup.sh
```

#### 2. Wrangler Not Found

**Problem**: `wrangler: command not found`

**Solution**:
```bash
npm install -g wrangler
wrangler login
```

#### 3. Backup Location Not Found

**Problem**: Backup fails because iCloud Drive is not available

**Solution**: Customize the backup location:
```bash
BACKUP_LOCATION="/path/to/accessible/location" npm run backup
```

#### 4. Type Check Failures

**Problem**: Deployment fails during type checking

**Solution**: The deployment will continue despite type check warnings. To fix type errors, review the TypeScript code and resolve issues.

#### 5. Authentication Errors

**Problem**: Deployment fails with authentication errors

**Solution**:
```bash
wrangler login
# Follow the authentication flow
```

### Getting Help

If you encounter issues:

1. **Check the logs**: Review the detailed logs in the `logs/` directory
2. **Verify prerequisites**: Ensure all required tools are installed and configured
3. **Check configuration**: Verify `deployment.config.json` and `backup.config.json` settings
4. **Review Cloudflare status**: Check if Cloudflare Workers is experiencing issues

### Debug Mode

For more verbose output, you can modify the scripts to include additional debugging:

```bash
# Run deployment with debug output
set -x  # Enable bash debug mode
./deploy.sh
```

## Best Practices

1. **Always backup before major deployments**: Use `npm run deploy:with-backup`
2. **Review logs regularly**: Check deployment and backup logs for issues
3. **Test deployments**: Use `wrangler dev` to test locally before deploying
4. **Keep backups off-site**: iCloud Drive provides automatic off-site backup
5. **Monitor deployment metadata**: Track deployments using the metadata JSON files
6. **Secure your credentials**: Never commit Cloudflare API tokens or secrets to git
7. **Use version control**: Commit code changes before deploying

## Next Steps

After setting up deployment and backup:

1. ✅ Test the deployment script: `npm run deploy:full`
2. ✅ Test the backup script: `npm run backup`
3. ✅ Verify backup location and contents
4. ✅ Review logs for any issues
5. ✅ Set up automated deployment workflows (optional)

## Additional Resources

- [Cloudflare Workers Documentation](https://developers.cloudflare.com/workers/)
- [Wrangler CLI Documentation](https://developers.cloudflare.com/workers/wrangler/)
- [D1 Database Documentation](https://developers.cloudflare.com/d1/)
