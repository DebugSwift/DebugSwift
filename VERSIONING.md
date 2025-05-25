# 📋 DebugSwift Versioning Strategy

This document outlines the versioning strategy for DebugSwift using GitVersion and GitHub Actions.

## 🎯 Overview

Our versioning strategy follows semantic versioning (SemVer) with automatic tagging and manual releases:

- **Develop Branch**: Automatic alpha tags (`v1.0.0-alpha.1`, `v1.0.0-alpha.2`)
- **Main Branch**: Manual releases with stable versions (`v1.0.0`, `v1.1.0`)
- **Feature Branches**: Development versions with branch names
- **Release Branches**: Beta versions for release candidates

## 🔧 Configuration Files

### GitVersion.yml
Controls version calculation and branch-specific versioning rules.

### GitHub Actions Workflows
- `.github/workflows/git-version.yml` - Auto tagging for develop/main
- `.github/workflows/manual-release.yml` - Manual release creation

## 🌿 Branch Strategy

### Main Branch (`main`)
- **Purpose**: Production-ready code
- **Versioning**: Stable releases (v1.0.0, v1.1.0, v2.0.0)
- **Increment**: Patch by default
- **Tagging**: Automatic on push
- **Releases**: Manual only

### Develop Branch (`develop`)
- **Purpose**: Integration branch for features
- **Versioning**: Alpha releases (v1.1.0-alpha.1, v1.1.0-alpha.2)
- **Increment**: Minor by default
- **Tagging**: Automatic on push
- **Releases**: None (alpha tags only)

### Feature Branches (`feature/*`)
- **Purpose**: New feature development
- **Versioning**: Feature versions (v1.1.0-feature-name.1)
- **Increment**: Inherits from target branch
- **Tagging**: None
- **Releases**: None

### Release Branches (`release/*`)
- **Purpose**: Release preparation and bug fixes
- **Versioning**: Beta versions (v1.1.0-beta.1)
- **Increment**: None (version locked)
- **Tagging**: Automatic
- **Releases**: Manual

### Hotfix Branches (`hotfix/*`)
- **Purpose**: Critical production fixes
- **Versioning**: Beta versions (v1.0.1-beta.1)
- **Increment**: Patch
- **Tagging**: Automatic
- **Releases**: Manual

## 📝 Semantic Version Control via Commit Messages

You can control version increments using special commit message tags:

### Major Version Bump
```bash
git commit -m "feat: breaking API changes +semver: major"
git commit -m "refactor: remove deprecated methods +semver: breaking"
```
**Result**: `1.0.0` → `2.0.0`

### Minor Version Bump
```bash
git commit -m "feat: add new authentication method +semver: minor"
git commit -m "feat: new debugging feature +semver: feature"
```
**Result**: `1.0.0` → `1.1.0`

### Patch Version Bump
```bash
git commit -m "fix: resolve memory leak issue +semver: patch"
git commit -m "fix: correct typo in error message +semver: fix"
```
**Result**: `1.0.0` → `1.0.1`

### Skip Version Increment
```bash
git commit -m "docs: update README +semver: none"
git commit -m "ci: update workflow +semver: skip"
```
**Result**: Version remains unchanged

## 🏷️ Version Examples

| Branch | Commit Message | Generated Version |
|--------|---------------|-------------------|
| `main` | `feat: new feature` | `v1.0.0` |
| `main` | `feat: breaking change +semver: major` | `v2.0.0` |
| `main` | `fix: bug fix +semver: patch` | `v1.0.1` |
| `develop` | `feat: new feature` | `v1.1.0-alpha.1` |
| `develop` | `fix: bug fix` | `v1.1.0-alpha.2` |
| `develop` | `feat: major change +semver: major` | `v2.0.0-alpha.1` |
| `release/1.5` | `fix: final fixes` | `v1.5.0-beta.1` |
| `feature/login` | `feat: add login` | `v1.1.0-login.1` |
| `hotfix/critical` | `fix: security issue` | `v1.0.1-beta.1` |

## 🚀 Release Process

### Automatic Alpha Releases (Develop)
1. Merge feature branch to `develop`
2. GitHub Actions automatically creates alpha tag
3. No release is created (tags only)

```bash
# Example workflow
git checkout develop
git merge feature/new-feature
git push origin develop
# → Creates v1.1.0-alpha.1 tag automatically
```

### Manual Production Releases (Main)
1. Merge `develop` to `main` (or hotfix to `main`)
2. Go to GitHub Actions → "Manual Release" workflow
3. Click "Run workflow"
4. Fill in release details:
   - **Tag name**: `v1.1.0`
   - **Release name**: `Release 1.1.0`
   - **Pre-release**: `false`
5. Workflow creates GitHub release

## ⚙️ Configuration Details

### Base Version Control
```yaml
next-version: 1.0.0  # Change this to set your next major version
tag-prefix: 'v'      # All tags prefixed with 'v'
```

### Commit Message Patterns
```yaml
major-version-bump-message: '\+semver:\s?(breaking|major)'
minor-version-bump-message: '\+semver:\s?(feature|minor)'
patch-version-bump-message: '\+semver:\s?(fix|patch)'
no-bump-message: '\+semver:\s?(none|skip)'
```

### Branch Patterns
```yaml
main: ^main$|^master$
develop: ^develop$|^dev$
release: ^releases?[/-]
feature: ^features?[/-]
hotfix: ^hotfix(es)?[/-]
```

## 🔄 Workflow Examples

### Adding a New Feature
```bash
# 1. Create feature branch from develop
git checkout develop
git pull origin develop
git checkout -b feature/awesome-feature

# 2. Develop and commit
git commit -m "feat: add awesome feature +semver: minor"

# 3. Merge to develop
git checkout develop
git merge feature/awesome-feature
git push origin develop
# → Creates v1.1.0-alpha.1 automatically

# 4. When ready for release, merge develop to main
git checkout main
git merge develop
git push origin main

# 5. Create manual release via GitHub Actions UI
# → Creates v1.1.0 release
```

### Hotfix Process
```bash
# 1. Create hotfix branch from main
git checkout main
git pull origin main
git checkout -b hotfix/critical-bug

# 2. Fix and commit
git commit -m "fix: resolve critical security issue +semver: patch"

# 3. Merge to main
git checkout main
git merge hotfix/critical-bug
git push origin main

# 4. Create manual release via GitHub Actions UI
# → Creates v1.0.1 release

# 5. Merge back to develop
git checkout develop
git merge main
git push origin develop
```

## 🛠️ Troubleshooting

### Changing Base Version
To start from a different version (e.g., v2.0.0):
1. Update `next-version: 2.0.0` in `GitVersion.yml`
2. Commit and push changes

### Force Version Override
Use commit message tags to override default increment:
```bash
git commit -m "feat: minor change that should be major +semver: major"
```

### Skip Version Increment
For documentation or CI changes:
```bash
git commit -m "docs: update documentation +semver: none"
```

## 📚 References

- [GitVersion Documentation](https://gitversion.net/)
- [Semantic Versioning](https://semver.org/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions) 