#!/bin/bash

# Exit if any command fails
set -e

# Get the current git branch
CURRENT_BRANCH=$(git symbolic-ref --short HEAD || echo "detached")
echo "Current branch: $CURRENT_BRANCH"

# First, make sure we're on a branch with the source code (not gh-pages)
if [ "$CURRENT_BRANCH" = "gh-pages" ]; then
  echo "Currently on gh-pages branch. Switching to main or master branch first..."
  if git show-ref --verify --quiet refs/heads/main; then
    git checkout main
    CURRENT_BRANCH="main"
  elif git show-ref --verify --quiet refs/heads/master; then
    git checkout master
    CURRENT_BRANCH="master"
  elif git show-ref --verify --quiet refs/heads/feature/websocket; then
    git checkout feature/websocket
    CURRENT_BRANCH="feature/websocket"
  else
    echo "Error: Could not find main, master, or feature/websocket branch to switch to."
    exit 1
  fi
  echo "Switched to $CURRENT_BRANCH branch"
fi

# Clean up any existing build directories to prevent conflicts
echo "Cleaning up existing build directories..."
rm -rf client/build/web
rm -rf temp_web

# Go to client directory
cd client

# Build Flutter web app
echo "Building Flutter web app..."
# Use root path for custom domain
flutter build web --release --base-href /

# Go back to project root
cd ..

# Create a temporary directory for gh-pages branch
echo "Creating temporary directory for gh-pages branch..."
mkdir -p temp_web
cp -R client/build/web/* temp_web/
# Copy CNAME file to ensure GitHub Pages uses the custom domain
cp CNAME temp_web/ 2>/dev/null || echo "CNAME file not found, creating it..."
if [ ! -f "temp_web/CNAME" ]; then
  echo "games.x51.vn" > temp_web/CNAME
  echo "Created CNAME file with games.x51.vn"
fi

# Verify temp_web directory has content
echo "Verifying temp_web directory contents:"
ls -la temp_web/

# Stash any changes in the current branch
git stash -u || echo "No changes to stash"

# Create or get the gh-pages branch
if git ls-remote --heads origin gh-pages | grep -q 'gh-pages'; then
  echo "Checking out existing gh-pages branch..."
  git checkout gh-pages
else
  echo "Creating new gh-pages branch..."
  git checkout --orphan gh-pages
  git reset --hard
  git commit --allow-empty -m "Initialize gh-pages branch"
  git push origin gh-pages
fi

# Clean the branch 
echo "Cleaning gh-pages branch..."
find . -maxdepth 1 ! -name .git ! -name . -exec rm -rf {} \;

# Copy the new build files from temp directory
echo "Copying web build files to gh-pages branch..."
cp -R temp_web/* .
rm -rf temp_web

# Add, commit and push the changes
echo "Committing and pushing changes to gh-pages branch..."
git add -A .
git commit -m "Update GitHub Pages deployment for games.x51.vn $(date)"
git push origin gh-pages

# Go back to the original branch
echo "Returning to $CURRENT_BRANCH branch..."
git checkout "$CURRENT_BRANCH"
git stash pop 2>/dev/null || echo "No stash to pop"

echo "Deployment complete! Your app should be available at https://games.x51.vn/"