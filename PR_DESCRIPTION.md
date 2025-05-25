# 🚀 Implement Automated Versioning Strategy with GitVersion

## 📋 Overview

This PR implements a comprehensive automated versioning strategy using GitVersion and GitHub Actions, providing better control over releases and alpha versioning for the DebugSwift project.

## 🎯 Key Changes

### ✨ **New Features**

- **Automatic Alpha Tagging**: Develop branch now automatically creates alpha tags (`v1.0.0-alpha.1`, `v1.0.0-alpha.2`)
- **Manual Release Control**: Main branch releases are now manual-only via GitHub Actions UI
- **Semantic Version Control**: Control version increments via commit messages using `+semver:` tags
- **GitVersion Integration**: Full GitVersion configuration for consistent versioning across branches

### 🔧 **Workflow Changes**

#### **Auto Tag and Version Workflow** (`.github/workflows/git-version.yml`)
- ✅ Automatic alpha tagging for `develop` branch merges
- ✅ Automatic stable tagging for `main` branch merges  
- ❌ Removed automatic releases (now manual-only)
- ❌ Removed CocoaPods publishing automation

#### **Manual Release Workflow** (`.github/workflows/manual-release.yml`)
- ✅ New workflow for creating manual releases
- ✅ Customizable tag names and release descriptions
- ✅ Pre-release option support
- ❌ Removed CocoaPods publishing

### 📝 **Configuration Files**

#### **GitVersion.yml** (New)
- Complete GitVersion configuration
- Branch-specific versioning rules
- Commit message-based version control
- Support for feature, release, and hotfix branches

#### **VERSIONING.md** (New)
- Comprehensive documentation of versioning strategy
- Workflow examples and troubleshooting
- Commit message patterns and branch strategies

## 🌿 **Branch Strategy**

| Branch Type | Versioning | Tagging | Releases |
|-------------|------------|---------|----------|
| `main` | Stable (v1.0.0) | ✅ Automatic | 🔧 Manual Only |
| `develop` | Alpha (v1.0.0-alpha.1) | ✅ Automatic | ❌ None |
| `feature/*` | Feature (v1.0.0-feature.1) | ❌ None | ❌ None |
| `release/*` | Beta (v1.0.0-beta.1) | ✅ Automatic | 🔧 Manual |
| `hotfix/*` | Beta (v1.0.1-beta.1) | ✅ Automatic | 🔧 Manual |

## 📝 **Semantic Version Control**

Control version increments using commit message tags:

```bash
# Major version bump (1.0.0 → 2.0.0)
git commit -m "feat: breaking API changes +semver: major"

# Minor version bump (1.0.0 → 1.1.0)  
git commit -m "feat: new feature +semver: minor"

# Patch version bump (1.0.0 → 1.0.1)
git commit -m "fix: bug fix +semver: patch"

# Skip version increment
git commit -m "docs: update README +semver: none"
```

## 🚀 **Release Process**

### **Development Workflow**
1. Create feature branch from `develop`
2. Merge feature to `develop` → **Automatic alpha tag created**
3. Merge `develop` to `main` when ready for release
4. **Manual release** via GitHub Actions UI

### **Manual Release Steps**
1. Go to **GitHub Actions** → **"Manual Release"** workflow
2. Click **"Run workflow"**
3. Enter:
   - Tag name (e.g., `v1.1.0`)
   - Release name (e.g., `Release 1.1.0`)
   - Pre-release flag (if needed)
4. Workflow creates GitHub release automatically

## 🔄 **Migration Impact**

### **Breaking Changes**
- ❌ **Removed automatic releases** for main branch
- ❌ **Removed CocoaPods automation** (manual publishing required)
- ✅ **Added manual release requirement** for production releases

### **Benefits**
- ✅ **Better release control** - No accidental releases
- ✅ **Automatic alpha versioning** - Clear development progression  
- ✅ **Semantic versioning** - Predictable version increments
- ✅ **Comprehensive documentation** - Clear workflow guidelines

## 📚 **Documentation**

- **[VERSIONING.md](VERSIONING.md)** - Complete versioning strategy guide
- **[GitVersion.yml](GitVersion.yml)** - Version calculation configuration
- **Updated README.md** - Links to versioning documentation

## 🧪 **Testing**

### **Scenarios Tested**
- ✅ Alpha tag creation on develop branch merge
- ✅ Stable tag creation on main branch merge  
- ✅ Manual release workflow execution
- ✅ Semantic version control via commit messages
- ✅ GitVersion configuration validation

### **Expected Behavior**
```bash
# Develop branch merge
develop → v1.1.0-alpha.1, v1.1.0-alpha.2, etc.

# Main branch merge  
main → v1.1.0 (tag only, manual release required)

# Manual release
GitHub UI → Creates v1.1.0 release
```

## 🔧 **Configuration**

### **Base Version Control**
```yaml
next-version: 1.0.0  # Starting version
tag-prefix: 'v'      # All tags prefixed with 'v'
```

### **Commit Message Patterns**
```yaml
major-version-bump-message: '\+semver:\s?(breaking|major)'
minor-version-bump-message: '\+semver:\s?(feature|minor)'  
patch-version-bump-message: '\+semver:\s?(fix|patch)'
no-bump-message: '\+semver:\s?(none|skip)'
```

## 🎯 **Future Considerations**

- Consider adding automated changelog generation
- Potential integration with release notes automation
- Swift Package Manager publishing automation (if needed)

## ✅ **Checklist**

- [x] GitVersion configuration implemented
- [x] Automatic alpha tagging for develop branch
- [x] Manual release workflow created
- [x] CocoaPods automation removed
- [x] Comprehensive documentation added
- [x] README updated with documentation links
- [x] Semantic version control implemented
- [x] Branch strategy documented
- [x] Workflow examples provided

---

**This PR establishes a robust, controlled versioning strategy that provides automatic development versioning while maintaining manual control over production releases.** 