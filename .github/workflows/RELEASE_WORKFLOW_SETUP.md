# Release Workflow Setup Guide

This document describes how to set up and use the automated release workflow for pushing releases to the public GitHub repository.

## Overview

The workflow automates the release process to the public GitHub repository (https://github.com/klaguerrePay/braintree_ruby). When a PR to the `automated_release_test` branch is merged, the workflow will:

1. Extract the version number from line 1 of `CHANGELOG.md`
2. Merge changes to the public repository's `master` branch with a squash commit
3. Create a commit with message: `releasing version {version}`
4. Create and push a git tag for the version
5. Push to the public repository's master branch

## Prerequisites

### Required Secrets

You need to configure the following GitHub secrets in your repository:

- **`GH_PAT`**: A GitHub Personal Access Token with access to the PayPal-Braintree organization (required to bypass IP allow list)
- **`PUBLIC_REPO_DEPLOY_KEY`**: An SSH private key with write access to the public repository

### Creating and Configuring the GitHub PAT

The PayPal-Braintree organization has an IP allow list enabled, which blocks GitHub Actions runners. You need a Personal Access Token (PAT) to authenticate.

#### Creating the PAT

1. Go to GitHub Settings (your personal account or a service account)
2. Navigate to: Settings → Developer settings → Personal access tokens → Fine-grained tokens (or Tokens (classic))
3. Click "Generate new token"

**For Fine-grained tokens** (recommended):
- Token name: `Braintree Ruby Release Automation`
- Expiration: Set according to your security policy (e.g., 1 year)
- Resource owner: Select `PayPal-Braintree`
- Repository access: Select "Only select repositories" → `braintree-ruby`
- Permissions:
  - Repository permissions → Contents: Read access
  - Repository permissions → Metadata: Read access (automatically granted)

**For Classic tokens** (if fine-grained is not available):
- Note: `Braintree Ruby Release Automation`
- Expiration: Set according to your security policy
- Scopes: Select `repo` (Full control of private repositories)

4. Click "Generate token"
5. **Copy the token immediately** (you won't be able to see it again)

#### Adding the PAT to Repository Secrets

1. Go to your repository: Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `GH_PAT`
4. Secret: Paste the PAT you just created
5. Click "Add secret"

### Creating and Configuring the SSH Deploy Key

#### Step 1: Generate an SSH Key Pair

On your local machine or a secure environment, generate a new SSH key pair specifically for this automation:

```bash
ssh-keygen -t ed25519 -C "release-automation@braintree" -f braintree_ruby_deploy_key
```

This will create two files:
- `braintree_ruby_deploy_key` (private key)
- `braintree_ruby_deploy_key.pub` (public key)

#### Step 2: Add the Public Key to the Target Repository

1. Go to the target repository: https://github.com/klaguerrePay/braintree_ruby
2. Navigate to: Settings → Deploy keys
3. Click "Add deploy key"
4. Title: `Release Automation Deploy Key` (or any descriptive name)
5. Key: Paste the contents of `braintree_ruby_deploy_key.pub`
6. **Important**: Check "Allow write access"
7. Click "Add key"

#### Step 3: Add the Private Key to Your Repository Secrets

1. Copy the contents of the **private key** file (`braintree_ruby_deploy_key`)
   ```bash
   cat braintree_ruby_deploy_key
   ```
2. Go to your repository settings (the repository where this workflow runs)
3. Navigate to: Settings → Secrets and variables → Actions
4. Click "New repository secret"
5. Name: `PUBLIC_REPO_DEPLOY_KEY`
6. Value: Paste the entire contents of the private key (including `-----BEGIN OPENSSH PRIVATE KEY-----` and `-----END OPENSSH PRIVATE KEY-----`)
7. Click "Add secret"

#### Step 4: Securely Delete the Key Files

After adding the keys to GitHub, securely delete the local key files:

```bash
shred -u braintree_ruby_deploy_key braintree_ruby_deploy_key.pub
# or if shred is not available:
rm -P braintree_ruby_deploy_key braintree_ruby_deploy_key.pub
```

## CHANGELOG.md Format

The workflow expects the first line of `CHANGELOG.md` to contain the version number in one of these formats:

```markdown
## 1.2.3
```

or

```markdown
# 1.2.3
```

The version must follow semantic versioning format: `MAJOR.MINOR.PATCH`

Example CHANGELOG.md:
```markdown
## 2.1.0
* Added new payment method support
* Fixed bug in transaction handling

## 2.0.1
* Bug fixes
```

## Usage

### 1. Prepare Your Release

- Ensure all changes are ready for release
- Update `CHANGELOG.md` with the new version on line 1
- Update any version files as needed (e.g., `lib/braintree/version.rb` for Ruby)
- Ensure tests are passing

### 2. Create a PR to `automated_release_test`

```bash
git checkout -b prepare-release-1.2.3
# Make your changes
# Update CHANGELOG.md, version files, etc.
git commit -am "Prepare release 1.2.3"
git push origin prepare-release-1.2.3
```

Create a PR targeting the `automated_release_test` branch and get it reviewed.

### 3. Merge the PR

Once approved, merge the PR to `automated_release_test`. The workflow will automatically trigger.

### 4. Monitor the Workflow

- Go to the "Actions" tab in your repository
- Find the "Release to Public GitHub" workflow run
- Monitor the progress and check logs if needed

### 5. Verify the Release

After the workflow completes successfully:

1. Check the public repository: https://github.com/klaguerrePay/braintree_ruby
2. Verify the commit message is: `releasing version X.Y.Z`
3. Verify the tag was created: https://github.com/klaguerrePay/braintree_ruby/tags
4. Verify the changes are in the master branch

## What the Workflow Does

Based on the original `cl_deploy.rb` script, the workflow performs these steps:

1. **Checkout**: Checks out the `automated_release_test` branch
2. **Version Extraction**: Reads the version from line 1 of CHANGELOG.md
3. **SSH Setup**: Configures SSH authentication using the deploy key
4. **Git Config**: Sets up git user as "Braintree <code@getbraintree.com>"
5. **Remote Setup**: Adds the public repository as a remote via SSH
6. **Merge**: Pulls public master and merges with `--squash` from automated_release_test
7. **Commit**: Creates a commit with message `releasing version X.Y.Z`
8. **Tag**: Creates an annotated git tag with the version number
9. **Push**: Pushes both the tag and the commit to public master

## Troubleshooting

### Version Extraction Fails

**Error**: "Could not extract version from CHANGELOG.md"

**Solution**:
- Verify that line 1 of CHANGELOG.md contains a valid version number
- The format must be: `## X.Y.Z` or `# X.Y.Z` where X, Y, Z are numbers
- Check for extra spaces or special characters

### SSH Authentication Fails

**Error**: "Permission denied (publickey)" or similar SSH errors

**Solution**:
- Verify that `PUBLIC_REPO_DEPLOY_KEY` secret is set correctly
- Ensure the corresponding public key is added as a deploy key in the target repo
- Verify "Allow write access" is checked on the deploy key
- Make sure you copied the entire private key including the header and footer lines

### Workflow Doesn't Trigger

**Possible causes**:
- The PR was closed but not merged - only merged PRs trigger the workflow
- The PR was not targeting the `automated_release_test` branch
- The workflow file doesn't exist in the default branch

### Merge Conflicts

If the workflow fails due to merge conflicts:
- Manually resolve conflicts between `automated_release_test` and the public master
- This might happen if the public repository has changes not in your internal repo

## What's Not Automated (Yet)

This workflow only handles the public GitHub release. The following steps from the original deploy script are **NOT** automated:

- Publishing to package managers (RubyGems, npm, PyPI, Maven Central, NuGet, etc.)
- Updating developer documentation (btdocsnodeweb)
- Merging back to internal master/release branches
- Running tests or builds
- Creating release notes or GitHub releases
- Updating version tracking files (versions.json in client-library-builds repo)

These steps should still be done manually or will be automated in future workflow additions.

## Security Notes

- The deploy key is scoped to only the target repository
- The private key is stored securely in GitHub Secrets (encrypted at rest)
- The key is only available to workflow runs, not to users
- You can rotate the key at any time by generating a new pair and updating both the deploy key and the secret
- Consider setting up branch protection rules on the `automated_release_test` branch to require reviews before merging
