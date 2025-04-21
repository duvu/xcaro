#!/bin/bash

# Exit if any command fails
set -e

# Get the current git branch
CURRENT_BRANCH=$(git symbolic-ref --short HEAD)
echo "Current branch: $CURRENT_BRANCH"

# Clean up any existing build directories to prevent conflicts
echo "Cleaning up existing build directories..."
rm -rf client/build/web
rm -rf temp_web

# Go to client directory
cd client

# Build Flutter web app
echo "Building Flutter web app..."
# Changed to use root path since we're using a custom domain
flutter build web --release --base-href /

# Go back to project root
cd ..

# Create a temporary directory for gh-pages branch
echo "Creating temporary directory for gh-pages branch..."
mkdir -p temp_web
cp -R client/build/web/* temp_web/
# Copy CNAME file to ensure GitHub Pages uses the custom domain
cp CNAME temp_web/ || echo "CNAME file not found, creating it..."
if [ ! -f "temp_web/CNAME" ]; then
  echo "games.x51.vn" > temp_web/CNAME
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