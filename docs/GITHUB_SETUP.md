# GitHub Repository Setup – bitzlatoview-mobile

Target: **https://github.com/ecozeentech/bitzlatoview-mobile**

## Option A: Automated (recommended)

Log in to GitHub CLI as **ecozeentech** (or an org admin):

```bash
gh auth login
./scripts/setup_github_repo.sh
```

## Option B: Manual via GitHub website

1. Go to [github.com/new](https://github.com/new)
2. Owner: **ecozeentech**
3. Repository name: **bitzlatoview-mobile**
4. Description: `Bitzlatoview Mobile – Flutter WebView app for Android and iOS`
5. Public or Private (your choice)
6. **Do not** initialize with README (we already have one)
7. Click **Create repository**

Then push from your machine:

```bash
cd bitzlatoview-mobile   # or your local clone path

git remote add mobile https://github.com/ecozeentech/bitzlatoview-mobile.git
git push mobile main --tags
git push mobile cursor/bitzlatoview-mobile-app-6cf7
```

## Option C: Rename existing repo

If you prefer to use the current repo (`-Bitzlatoview-App`):

1. GitHub → **Settings** → **General** → **Repository name**
2. Rename to `bitzlatoview-mobile`
3. Update local remote:

```bash
git remote set-url origin https://github.com/ecozeentech/bitzlatoview-mobile.git
```

## Verify

- [ ] All files visible on GitHub
- [ ] No `google-services.json` or `GoogleService-Info.plist` (only `.example` files)
- [ ] No `android/key.properties` or `.keystore` files
- [ ] README renders correctly
- [ ] Tag `v1.0.0` exists under Releases

## Enable GitHub Actions

After push, **Actions** tab should show the Flutter CI workflow on the next push to `main`.

## Branch protection (optional)

Settings → Branches → Add rule for `main`:
- Require pull request reviews
- Require status checks: `test`
