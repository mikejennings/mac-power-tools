# Mac Power Tools - Local Development Workflow

This project uses a **local-only development workflow** without GitHub Actions to avoid costs and maintain full control over the release process.

## Quick Start

```bash
# 1. Make your changes
# 2. Run tests
./local-test.sh

# 3. Bump version
./bump-version.sh

# 4. Create release
./local-release.sh release
```

## Available Scripts

### 🧪 Testing: `local-test.sh`

Comprehensive test suite that replaces GitHub Actions CI/CD.

```bash
# Run all tests
./local-test.sh

# Run quick tests only (syntax, permissions, version)
./local-test.sh quick

# Run specific test
./local-test.sh syntax      # Bash syntax check
./local-test.sh shellcheck  # ShellCheck analysis
./local-test.sh deps        # Check dependencies
./local-test.sh unit        # Run unit tests
./local-test.sh version     # Check version consistency
./local-test.sh permissions # Check file permissions
./local-test.sh issues      # Check for common issues
```

**Features:**
- ✅ Bash syntax validation
- ✅ ShellCheck linting (if installed)
- ✅ File permission checks
- ✅ Version consistency validation
- ✅ Dependency checking
- ✅ Unit test execution
- ✅ Common issue detection

### 📦 Release Management: `local-release.sh`

Complete release management without GitHub Actions.

```bash
# Interactive menu
./local-release.sh

# Full release (tests, archive, tag, homebrew)
./local-release.sh release

# Individual steps
./local-release.sh test      # Run tests only
./local-release.sh archive   # Create release archive
./local-release.sh tag       # Create git tag
./local-release.sh homebrew  # Update Homebrew formula
./local-release.sh checklist # Show release checklist
```

**Features:**
- ✅ Creates release archives (.tar.gz)
- ✅ Generates SHA256 checksums
- ✅ Creates and pushes git tags
- ✅ Updates Homebrew formula locally
- ✅ Interactive release checklist

### 🔢 Version Bumping: `bump-version.sh`

Interactive version management with integrated workflow.

```bash
./bump-version.sh
```

**Features:**
- ✅ Semantic versioning (patch/minor/major)
- ✅ Updates all version references
- ✅ Adds changelog entries
- ✅ Commits changes locally
- ✅ Optionally runs tests
- ✅ Optionally creates release

## Complete Release Workflow

### 1. Development Phase
```bash
# Make your changes
vim scripts/mac-something.sh

# Test your changes
./local-test.sh quick
```

### 2. Pre-Release Phase
```bash
# Run full test suite
./local-test.sh

# Fix any issues found
# Re-run tests until all pass
```

### 3. Release Phase
```bash
# Bump version (includes changelog)
./bump-version.sh
# Select version type (patch/minor/major)
# Enter changelog entry
# Commit changes

# Create release
./local-release.sh release
# This will:
# - Run tests again
# - Create release archive
# - Generate SHA256
# - Create git tag
# - Update Homebrew formula (if configured)
```

### 4. Distribution Phase
```bash
# Push to GitHub
git push origin master
git push origin --tags

# Test Homebrew installation
brew upgrade mac-power-tools
```

## Why Local-Only?

### ✅ Advantages
- **No costs**: GitHub Actions can charge for private repos
- **Full control**: Everything runs on your machine
- **Faster feedback**: No waiting for CI/CD pipelines
- **Privacy**: Keep development local until ready
- **Simplicity**: No YAML debugging or workflow issues
- **Reliability**: No external service dependencies

### 📋 Requirements
- **Required**: bash, git
- **Recommended**: shellcheck (`brew install shellcheck`)
- **Optional**: GitHub CLI for releases (`brew install gh`)

## Troubleshooting

### Tests failing?
```bash
# Run specific test for details
./local-test.sh syntax
./local-test.sh shellcheck

# Check for common issues
./local-test.sh issues
```

### Release not working?
```bash
# Check release checklist
./local-release.sh checklist

# Run steps individually
./local-release.sh test
./local-release.sh archive
./local-release.sh tag
```

### Version mismatch?
```bash
# Check version consistency
./local-test.sh version

# Fix with bump-version.sh
./bump-version.sh
```

## Migration from GitHub Actions

If you previously used GitHub Actions:

1. **Remove workflows**: Already done! `.github/` directory removed
2. **Use local scripts**: All functionality replaced locally
3. **Update git hooks** (optional):
   ```bash
   # Add pre-commit hook for testing
   echo '#!/bin/bash
   ./local-test.sh quick' > .git/hooks/pre-commit
   chmod +x .git/hooks/pre-commit
   ```

## Contributing

When contributing to this project:

1. Fork the repository
2. Use the local scripts for testing
3. Ensure all tests pass: `./local-test.sh`
4. Submit pull request with test results

## Support

- **Issues**: Report bugs on GitHub Issues
- **Questions**: Check existing documentation
- **Scripts**: All scripts have `--help` options

---

*This local workflow ensures zero costs, full control, and reliable releases!*