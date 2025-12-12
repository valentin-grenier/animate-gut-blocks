#!/bin/bash

# Exit on error
set -e

# Parse arguments
TEST_MODE=false
if [[ "$1" == "--test" || "$1" == "-t" ]]; then
    TEST_MODE=true
    echo "🧪 Running in TEST MODE - no commits will be made"
fi

# Configuration
PLUGIN_SLUG="simple-block-animations"
SVN_URL="https://plugins.svn.wordpress.org/$PLUGIN_SLUG"
SVN_DIR="$HOME/dev/plugins/$PLUGIN_SLUG"

# Get the plugin directory (parent of bin/)
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Get version from main plugin file
VERSION=$(grep -i "Version:" "$PLUGIN_DIR"/*.php | head -1 | awk '{print $3}')

if [ -z "$VERSION" ]; then
    echo "❌ Error: Could not determine plugin version"
    exit 1
fi

echo "🚀 Deploying $PLUGIN_SLUG v$VERSION"

# Build the project
echo "🔨 Building project..."
cd "$PLUGIN_DIR"

# Check if node_modules exists, install if needed
if [ ! -d "$PLUGIN_DIR/node_modules" ]; then
    echo "📦 Installing npm dependencies..."
    npm install
fi

# Run build
npm run build

if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

echo "✅ Build completed"

# Check if .distignore exists
if [ ! -f "$PLUGIN_DIR/.distignore" ]; then
    echo "⚠️  Warning: .distignore file not found"
    read -p "Continue without .distignore? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Deployment cancelled"
        exit 1
    fi
fi

# Checkout or update SVN
if [ ! -d "$SVN_DIR" ]; then
    echo "📥 Checking out SVN repository..."
    svn co "$SVN_URL" "$SVN_DIR"
else
    echo "🔄 Updating SVN repository..."
    cd "$SVN_DIR" && svn up
fi

# Clean trunk directory
echo "🧹 Cleaning trunk directory..."
if [ -d "$SVN_DIR/trunk" ]; then
    # Remove all files except .svn
    find "$SVN_DIR/trunk" -mindepth 1 -maxdepth 1 ! -name '.svn' -exec rm -rf {} +
fi

# Copy files using rsync, respecting .distignore
echo "📦 Copying files..."
if [ -f "$PLUGIN_DIR/.distignore" ]; then
    rsync -av --delete \
        --exclude-from="$PLUGIN_DIR/.distignore" \
        --exclude='.svn' \
        --exclude="$SVN_DIR" \
        "$PLUGIN_DIR/" "$SVN_DIR/trunk/"
else
    rsync -av --delete \
        --exclude='.svn' \
        --exclude="$SVN_DIR" \
        "$PLUGIN_DIR/" "$SVN_DIR/trunk/"
fi

# Go to SVN directory
cd "$SVN_DIR"

# Handle additions/deletions
echo "📋 Adding new files to SVN..."
svn status | grep '^\?' | awk '{print $2}' | xargs -r -I {} svn add {}
svn status | grep '^\!' | awk '{print $2}' | xargs -r -I {} svn delete {}

# Display changes
echo "📝 Changes to commit:"
svn status

# If test mode, exit here
if [ "$TEST_MODE" = true ]; then
    echo ""
    echo "🧪 TEST MODE - Stopping here"
    echo "✅ Everything looks good! Files are ready in: $SVN_DIR/trunk"
    echo "To deploy for real, run without --test flag"
    exit 0
fi

# Ask for confirmation
read -p "Commit these changes? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "📤 Committing to trunk..."
    svn ci -m "Update trunk to version $VERSION"
    
    # Check if tag already exists
    if svn ls "$SVN_URL/tags/$VERSION" > /dev/null 2>&1; then
        echo "⚠️  Tag $VERSION already exists"
        read -p "Delete and recreate tag? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "🗑️  Removing existing tag..."
            svn rm "$SVN_URL/tags/$VERSION" -m "Removing tag $VERSION for recreation"
        else
            echo "✅ Trunk updated, skipping tag creation"
            exit 0
        fi
    fi
    
    # Create tag from trunk URL (not local trunk)
    echo "🏷️  Creating tag $VERSION..."
    svn cp "$SVN_URL/trunk" "$SVN_URL/tags/$VERSION" -m "Tagging version $VERSION"
    
    echo "✅ Deployment completed!"
else
    echo "❌ Deployment cancelled"
fi