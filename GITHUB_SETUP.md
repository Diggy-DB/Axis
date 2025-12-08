# GitHub Setup Guide

This guide will help you push the Axis project to GitHub as a private repository while keeping sensitive data secure.

## ⚠️ Security Checklist (COMPLETE BEFORE PUSHING!)

Before pushing to GitHub, ensure:

- [ ] All `.env` files are created and filled with your actual values
- [ ] All `.env` files are listed in `.gitignore`
- [ ] Firebase service account keys are NOT in the repository
- [ ] `GoogleService-Info.plist` files are NOT in the repository
- [ ] No API keys, passwords, or secrets in any committed files

## 📋 Pre-Push Setup

### 1. Set Up Environment Variables

#### Flutter App (axis/)
```bash
cd axis
cp .env.example .env
```

Edit `axis/.env` and fill in your Firebase credentials from:
- Firebase Console → Project Settings → General
- Your downloaded `GoogleService-Info.plist` files

#### Python Backend (ai_backend/)
```bash
cd ai_backend
cp .env.example .env
```

Edit `ai_backend/.env` and fill in:
- Path to Firebase service account JSON key
- Or individual Firebase Admin SDK credentials

#### Root Directory
```bash
cd /Users/diggy/Productive
cp .env.example .env
```

Edit `.env` with your project-wide configuration.

### 2. Verify .gitignore Protection

Run this command to verify sensitive files are ignored:

```bash
# From the Productive directory
git status --ignored

# You should see .env files in the ignored section
# You should NOT see any .env files in "Changes to be committed"
```

### 3. Test Locally First

Before pushing, test that everything works with your `.env` files:

```bash
# Test Flutter app
cd axis
flutter pub get
flutter run -d macos

# Test Python backend
cd ai_backend
source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload
```

## 🚀 Push to GitHub

### Option 1: Create New Private Repository (Recommended)

```bash
# Navigate to project root
cd /Users/diggy/Productive

# Initialize git (if not already done)
git init

# Add all files
git add .

# Verify no sensitive files are staged
git status

# Create initial commit
git commit -m "Initial commit: Axis Life Operating System

- Complete Flutter multi-platform app structure
- Python FastAPI AI backend with recommendation engine
- Comprehensive documentation (10,000+ words)
- Responsive design for iPhone, iPad, MacBook
- 6 life domain organization system
- State management with Provider pattern
- Firestore integration ready
- Rule-based AI v1 with ML upgrade path"

# Create repository on GitHub.com
# Go to: https://github.com/new
# Name: axis (or your preferred name)
# Description: Multi-platform life operating system with AI recommendations
# Privacy: Private ✓
# Do NOT initialize with README, .gitignore, or license

# Link your local repo to GitHub
git remote add origin https://github.com/YOUR_USERNAME/axis.git

# Push to GitHub
git branch -M main
git push -u origin main
```

### Option 2: Using GitHub CLI (gh)

```bash
# Navigate to project root
cd /Users/diggy/Productive

# Initialize git
git init
git add .
git commit -m "Initial commit: Axis Life Operating System"

# Create private repository and push (requires GitHub CLI)
gh repo create axis --private --source=. --push
```

## 🔐 GitHub Secrets Setup

For CI/CD or GitHub Actions, add these secrets:

1. Go to your repository on GitHub
2. Navigate to: Settings → Secrets and variables → Actions
3. Add the following secrets:

### Required Secrets:

- `FIREBASE_API_KEY` - Your Firebase API key
- `FIREBASE_PROJECT_ID` - Your Firebase project ID
- `FIREBASE_SERVICE_ACCOUNT_KEY` - Your Firebase service account JSON (entire file as secret)
- `GOOGLE_APPLICATION_CREDENTIALS` - Service account key for backend

### Optional (for deployment):

- `GCP_PROJECT_ID` - Google Cloud project ID
- `GCP_SA_KEY` - Service account for Cloud Run deployment
- `APPLE_CERTIFICATE` - For iOS/macOS code signing
- `APPLE_PROVISIONING_PROFILE` - Provisioning profiles

## 📁 Repository Structure on GitHub

Your repository will look like this:

```
axis/
├── .github/                 # (Optional) GitHub Actions workflows
├── ai_backend/              # Python FastAPI backend
│   ├── .env.example        ✅ COMMITTED
│   ├── .env                ❌ IGNORED
│   └── serviceAccountKey.json  ❌ IGNORED
├── axis/                    # Flutter app
│   ├── .env.example        ✅ COMMITTED
│   ├── .env                ❌ IGNORED
│   ├── ios/
│   │   └── Runner/
│   │       └── GoogleService-Info.plist  ❌ IGNORED
│   └── macos/
│       └── Runner/
│           └── GoogleService-Info.plist  ❌ IGNORED
├── .env.example            ✅ COMMITTED
├── .env                    ❌ IGNORED
├── README.md               ✅ COMMITTED
├── ARCHITECTURE.md         ✅ COMMITTED
├── SETUP_GUIDE.md          ✅ COMMITTED
├── IMPLEMENTATION_GUIDE.md ✅ COMMITTED
├── PROJECT_SUMMARY.md      ✅ COMMITTED
└── GITHUB_SETUP.md         ✅ COMMITTED (this file)
```

## 👥 Team Collaboration Setup

If you're working with a team:

### 1. Share .env.example Files

Team members should:
```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/axis.git
cd axis

# Copy example files
cp .env.example .env
cp axis/.env.example axis/.env
cp ai_backend/.env.example ai_backend/.env

# Request credentials from project admin
# Fill in .env files with shared credentials
```

### 2. Use a Secure Secret Sharing Method

- **1Password** - Share vault with team
- **Bitwarden** - Team organization
- **Google Cloud Secret Manager**
- **AWS Secrets Manager**
- **HashiCorp Vault**

**NEVER share secrets via:**
- ❌ Email
- ❌ Slack/Discord
- ❌ Text message
- ❌ Committed files

### 3. Set Up Branch Protection

On GitHub:
1. Settings → Branches
2. Add rule for `main` branch
3. Enable:
   - Require pull request reviews
   - Require status checks to pass
   - Require branches to be up to date

## 🔄 Updating the Repository

### Daily Workflow

```bash
# Check status
git status

# Stage changes
git add .

# Commit with descriptive message
git commit -m "feat: add habit streak calculation logic"

# Pull latest changes
git pull origin main

# Push your changes
git push origin main
```

### Conventional Commit Messages

Use semantic commit messages:
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting)
- `refactor:` Code restructuring
- `test:` Adding tests
- `chore:` Maintenance tasks

Examples:
```bash
git commit -m "feat: implement Calendar screen with event filtering"
git commit -m "fix: resolve habit streak calculation bug"
git commit -m "docs: update SETUP_GUIDE with Xcode configuration"
git commit -m "refactor: extract habit card to reusable widget"
```

## 🛡️ Security Best Practices

### 1. Audit Commits for Secrets

Before pushing, scan for accidentally committed secrets:

```bash
# Install git-secrets
brew install git-secrets

# Set up for your repo
cd /Users/diggy/Productive
git secrets --install
git secrets --register-aws

# Scan repository
git secrets --scan
```

### 2. Enable GitHub Security Features

In your repository settings:
- ✅ Enable "Vulnerability alerts"
- ✅ Enable "Dependabot alerts"
- ✅ Enable "Dependabot security updates"
- ✅ Enable "Code scanning" (GitHub Advanced Security)

### 3. Regular Security Audits

```bash
# Flutter dependencies
cd axis
flutter pub outdated

# Python dependencies
cd ai_backend
pip list --outdated

# Check for known vulnerabilities
pip-audit
```

## 📞 Emergency: Leaked Secrets

If you accidentally commit secrets:

### 1. Immediately Revoke Credentials
- Firebase: Regenerate API keys
- Service accounts: Delete and create new ones
- Access tokens: Revoke immediately

### 2. Remove from Git History
```bash
# Remove sensitive file from all commits
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch path/to/sensitive/file" \
  --prune-empty --tag-name-filter cat -- --all

# Force push (WARNING: Rewrites history)
git push origin --force --all
```

### 3. Better Solution: Use BFG Repo-Cleaner
```bash
# Install BFG
brew install bfg

# Remove sensitive data
bfg --delete-files sensitive_file.json
bfg --replace-text passwords.txt  # File with strings to replace

# Clean up
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Force push
git push origin --force --all
```

## ✅ Final Checklist

Before considering setup complete:

- [ ] Repository is private on GitHub
- [ ] All `.env.example` files are committed
- [ ] All actual `.env` files are in `.gitignore`
- [ ] No secrets visible in commit history (`git log -p | grep -i "api_key"`)
- [ ] README.md clearly states project is for personal use
- [ ] SETUP_GUIDE.md instructs cloners to create `.env` files
- [ ] Team members can clone and run with their own credentials
- [ ] Branch protection rules are set (if working with team)
- [ ] Dependabot alerts are enabled
- [ ] You have a backup of your `.env` files locally (NOT in git)

## 🎉 You're All Set!

Your Axis project is now:
- ✅ Safely stored on GitHub
- ✅ Protected from credential leaks
- ✅ Ready for team collaboration
- ✅ Set up for CI/CD (when ready)

**Next Steps:**
1. Complete Firebase setup (SETUP_GUIDE.md)
2. Implement remaining screens (IMPLEMENTATION_GUIDE.md)
3. Test on all target platforms
4. Set up GitHub Actions for automated testing (optional)
5. Deploy backend to Cloud Run (optional)

---

**Questions?** Refer to:
- SETUP_GUIDE.md for Firebase and development setup
- ARCHITECTURE.md for system design decisions
- GitHub's security documentation: https://docs.github.com/en/code-security
