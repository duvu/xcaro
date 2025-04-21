#!/bin/bash

# Exit if any command fails
set -e

# Get the current git branch
CURRENT_BRANCH=$(git symbolic-ref --short HEAD)
echo "Current branch: $CURRENT_BRANCH"

# Go to client directory
cd client

# Build Flutter web app
echo "Building Flutter web app..."
flutter build web --release --base-href /xcaro/

# Go back to project root
cd ..

# Create a temporary directory for gh-pages branch
echo "Creating temporary directory for gh-pages branch..."
mkdir -p temp_web
cp -R client/build/web/* temp_web/

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

# Clean the branch and copy the web build
echo "Updating gh-pages branch with new build..."
# Use --ignore-unmatch to prevent errors if no files exist
git rm -rf --ignore-unmatch ./*
# Copy the new build files from temp directory
cp -R temp_web/* .
rm -rf temp_web

# Add, commit and push the changes
echo "Committing and pushing changes to gh-pages branch..."
git add -A .
git commit -m "Update GitHub Pages deployment $(date)"
git push origin gh-pages

# Go back to the original branch
echo "Returning to $CURRENT_BRANCH branch..."
git checkout "$CURRENT_BRANCH"

echo "Deployment complete! Your app should be available at https://duvu.github.io/xcaro/"