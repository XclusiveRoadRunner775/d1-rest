# Quick Reference: Deployment & Backup

## 🚀 Deployment Commands

### Basic Deployment
```bash
npm run deploy
```
Simple wrangler deployment (existing method)

### Full Deployment (Recommended)
```bash
npm run deploy:full
```
Complete deployment with:
- Prerequisites check
- Dependency installation
- Type checking
- Comprehensive logging
- Deployment metadata

### Deployment with Backup
```bash
npm run deploy:with-backup
```
Automatically backup before deploying

## 💾 Backup Commands

### Create Backup
```bash
npm run backup
```
Creates timestamped backup to iCloud

### Custom Backup Location
```bash
BACKUP_LOCATION="/path/to/backup" npm run backup
```

### Custom Backup Retention
```bash
BACKUP_KEEP_COUNT=20 npm run backup
```

## 📁 File Structure

```
d1-rest/
├── deploy.sh                    # Deployment automation script
├── backup.sh                    # Backup automation script
├── deployment.config.json       # Deployment configuration
├── backup.config.json          # Backup configuration
├── DEPLOYMENT.md               # Full documentation
├── logs/                       # Auto-generated logs
│   ├── deployment_*.log        # Deployment logs
│   ├── deployment_metadata_*.json
│   └── backup_*.log            # Backup logs
└── src/                        # Source code
    ├── index.ts                # Main worker file
    └── rest.ts                 # REST API handlers
```

## 🔧 Configuration Files

### deployment.config.json
Controls deployment behavior:
- Environment settings
- Auto-backup before deploy
- Type checking
- Logging preferences

### backup.config.json
Controls backup behavior:
- Backup location
- Retention policy (keep_count)
- Exclude patterns
- Auto-backup on deploy

## 📊 Logs Location

All logs are saved in the `logs/` directory:
- `deployment_YYYYMMDD_HHMMSS.log` - Deployment logs
- `deployment_metadata_YYYYMMDD_HHMMSS.json` - Deployment metadata
- `backup_YYYYMMDD_HHMMSS.log` - Backup logs

## 🛠️ Useful Commands

### View Latest Deployment Log
```bash
ls -t logs/deployment_*.log | head -1 | xargs cat
```

### View Latest Backup Log
```bash
ls -t logs/backup_*.log | head -1 | xargs cat
```

### Check Latest Backup
```bash
ls -la ~/Library/Mobile\ Documents/com~apple~CloudDocs/d1-rest-backups/latest/
```

### Local Development
```bash
npm run dev        # Start local development server
npm start          # Alias for npm run dev
```

### Type Generation
```bash
npm run cf-typegen  # Generate TypeScript types from wrangler config
```

## 🔍 Troubleshooting

### Make Scripts Executable
```bash
chmod +x deploy.sh backup.sh
```

### Check Prerequisites
```bash
node --version
npm --version
wrangler --version
rsync --version
```

### Wrangler Authentication
```bash
wrangler login
```

## 📚 Documentation

For complete documentation, see [DEPLOYMENT.md](./DEPLOYMENT.md)

## ⚡ Quick Setup

```bash
# 1. Install dependencies
npm install

# 2. Make scripts executable
chmod +x deploy.sh backup.sh

# 3. Configure Cloudflare (first time only)
wrangler login

# 4. Test deployment (dry run - local dev)
npm run dev

# 5. Create first backup
npm run backup

# 6. Deploy to production
npm run deploy:full
```

## 🎯 Best Practices

1. ✅ Always backup before major changes: `npm run deploy:with-backup`
2. ✅ Review logs after deployment
3. ✅ Test locally with `npm run dev` first
4. ✅ Keep backups off-site (iCloud)
5. ✅ Monitor deployment metadata files
6. ✅ Use version control (git) for all code changes

## 🔐 Security Notes

- Never commit API keys or secrets to git
- Store sensitive data in Cloudflare Secrets Store
- Review `.gitignore` to ensure logs and sensitive files are excluded
- Use environment variables for sensitive configuration

## 📞 Support

For issues or questions:
1. Check logs in `logs/` directory
2. Review full documentation in `DEPLOYMENT.md`
3. Verify prerequisites are installed
4. Check Cloudflare Workers status
