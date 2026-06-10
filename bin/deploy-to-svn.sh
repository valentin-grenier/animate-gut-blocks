#!/bin/bash

# ──────────────────────────────────────────────────────────────────────────
# NOTE : Le déploiement OFFICIEL vers WordPress.org passe désormais par
# GitHub Actions (.github/workflows/deploy.yml, action 10up) et se déclenche
# à la publication d'une Release GitHub.
#
# Ce script reste disponible comme solution de secours / pour un déploiement
# manuel local, mais ne l'utilise pas en parallèle d'une Release GitHub pour
# la même version (cela créerait un double commit/tag SVN).
# ──────────────────────────────────────────────────────────────────────────

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

# Get current version from main plugin file
CURRENT_VERSION=$(grep -i "Version:" "$PLUGIN_DIR"/*.php | head -1 | awk '{print $3}')

if [ -z "$CURRENT_VERSION" ]; then
    echo "❌ Error: Could not determine plugin version"
    exit 1
fi

echo "📌 Current version: $CURRENT_VERSION"
echo ""
echo "Select release type:"
echo "  1) Patch (bug fix)     - e.g., $CURRENT_VERSION → $(echo $CURRENT_VERSION | awk -F. '{print $1"."$2"."$3+1}')"
echo "  2) Minor (new feature) - e.g., $CURRENT_VERSION → $(echo $CURRENT_VERSION | awk -F. '{print $1"."$2+1".0"}')"
echo "  3) Major (breaking)    - e.g., $CURRENT_VERSION → $(echo $CURRENT_VERSION | awk -F. '{print $1+1".0.0"}')"
echo "  4) Custom version"
echo "  5) Use current version ($CURRENT_VERSION)"
echo ""
read -p "Enter choice (1-5): " -n 1 -r RELEASE_TYPE
echo
echo

case $RELEASE_TYPE in
    1)
        # Patch: increment last digit (1.0.1 → 1.0.2)
        VERSION=$(echo $CURRENT_VERSION | awk -F. '{print $1"."$2"."$3+1}')
        RELEASE_NAME="Patch"
        ;;
    2)
        # Minor: increment middle digit, reset last (1.0.1 → 1.1.0)
        VERSION=$(echo $CURRENT_VERSION | awk -F. '{print $1"."$2+1".0"}')
        RELEASE_NAME="Minor"
        ;;
    3)
        # Major: increment first digit, reset others (1.0.1 → 2.0.0)
        VERSION=$(echo $CURRENT_VERSION | awk -F. '{print $1+1".0.0"}')
        RELEASE_NAME="Major"
        ;;
    4)
        # Custom version
        read -p "Enter custom version (e.g., 1.2.3): " VERSION
        RELEASE_NAME="Custom"
        ;;
    5)
        # Keep current version
        VERSION=$CURRENT_VERSION
        RELEASE_NAME="Current"
        ;;
    *)
        echo "❌ Invalid choice. Exiting."
        exit 1
        ;;
esac

echo "🚀 Deploying $PLUGIN_SLUG v$VERSION ($RELEASE_NAME release)"

# Function to update version in plugin file
update_version_in_file() {
    local file="$1"
    local new_version="$2"
    
    # Update Version header
    sed -i "s/Version:.*$/Version: $new_version/" "$file"
    
    # Update version constant if it exists
    sed -i "s/define( 'SIMPBLAN_VERSION', '[^']*' );/define( 'SIMPBLAN_VERSION', '$new_version' );/" "$file"
    
    echo "✅ Updated version in $file"
}

# Update version in main plugin file if version changed
if [ "$VERSION" != "$CURRENT_VERSION" ]; then
    echo "📝 Updating version in plugin file..."
    MAIN_FILE=$(find "$PLUGIN_DIR" -maxdepth 1 -name "*.php" -type f | head -1)
    update_version_in_file "$MAIN_FILE" "$VERSION"
    
    # Update readme.txt stable tag if it exists
    if [ -f "$PLUGIN_DIR/readme.txt" ]; then
        sed -i "s/^Stable tag:.*$/Stable tag: $VERSION/" "$PLUGIN_DIR/readme.txt"
        echo "✅ Updated stable tag in readme.txt"
    fi
fi

# Get changelog/commit message
echo ""
echo "📝 Enter changelog for this release:"
echo "   (This will appear in the WordPress.org repository)"
echo "   Tip: Use bullet points with * or -"
echo "   (Press Enter twice when done, or leave empty for default message)"
echo ""

# Check if we can use multi-line input
if [ -t 0 ]; then
    # Interactive mode - collect lines until empty line
    COMMIT_MESSAGE=""
    while true; do
        read -r line
        if [ -z "$line" ]; then
            if [ -n "$COMMIT_MESSAGE" ] || [ -z "$COMMIT_MESSAGE" ]; then
                break
            fi
        else
            if [ -z "$COMMIT_MESSAGE" ]; then
                COMMIT_MESSAGE="$line"
            else
                COMMIT_MESSAGE="$COMMIT_MESSAGE"$'\n'"$line"
            fi
        fi
    done
    
    # If empty, use default
    if [ -z "$COMMIT_MESSAGE" ]; then
        COMMIT_MESSAGE="Update to version $VERSION"
    fi
else
    COMMIT_MESSAGE="Update to version $VERSION"
fi

echo ""
echo "Changelog to be used:"
echo "---"
echo "$COMMIT_MESSAGE"
echo "---"
echo ""

# Function to update changelog in readme.txt
update_readme_changelog() {
    local readme_file="$1"
    local version="$2"
    local changelog="$3"
    
    if [ ! -f "$readme_file" ]; then
        echo "⚠️  readme.txt not found, skipping changelog update"
        return
    fi
    
    # Check if changelog section exists
    if ! grep -q "== Changelog ==" "$readme_file"; then
        echo "⚠️  Changelog section not found in readme.txt"
        return
    fi
    
    # Format the changelog entry
    local changelog_entry="= $version =\n"
    
    # Process each line of the commit message
    while IFS= read -r line; do
        # If line doesn't start with * or -, add it
        if [[ "$line" =~ ^[*-] ]]; then
            changelog_entry+="$line\n"
        else
            # Add * prefix if not empty
            if [ -n "$line" ]; then
                changelog_entry+="* $line\n"
            fi
        fi
    done <<< "$changelog"
    
    # Create a temporary file
    local temp_file=$(mktemp)
    
    # Insert new changelog entry after "== Changelog =="
    awk -v entry="$changelog_entry" '
        /^== Changelog ==/ {
            print $0
            print ""
            printf "%s", entry
            print ""
            next
        }
        { print }
    ' "$readme_file" > "$temp_file"
    
    # Replace original file
    mv "$temp_file" "$readme_file"
    
    echo "✅ Updated Changelog section in readme.txt"
}

# Update readme.txt with changelog
if [ -f "$PLUGIN_DIR/readme.txt" ]; then
    update_readme_changelog "$PLUGIN_DIR/readme.txt" "$VERSION" "$COMMIT_MESSAGE"
fi

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
    
    # Prepare commit message
    SVN_COMMIT_MSG="Version $VERSION - $RELEASE_NAME release

$COMMIT_MESSAGE"
    
    svn ci -m "$SVN_COMMIT_MSG"
    
    # Check if tag already exists and auto-increment if needed
    FINAL_VERSION=$VERSION
    if svn ls "$SVN_URL/tags/$VERSION" > /dev/null 2>&1; then
        echo ""
        echo "⚠️  Tag $VERSION already exists!"
        echo "🔄 Auto-incrementing to next patch version..."
        
        # Extract version parts
        MAJOR=$(echo $VERSION | cut -d. -f1)
        MINOR=$(echo $VERSION | cut -d. -f2)
        PATCH=$(echo $VERSION | cut -d. -f3)
        
        # Increment patch version until we find an unused tag
        while svn ls "$SVN_URL/tags/$MAJOR.$MINOR.$PATCH" > /dev/null 2>&1; do
            PATCH=$((PATCH + 1))
        done
        
        FINAL_VERSION="$MAJOR.$MINOR.$PATCH"
        echo "✅ Using version $FINAL_VERSION instead"
        echo ""
    fi
    
    # Create tag from trunk URL (not local trunk)
    echo "🏷️  Creating tag $FINAL_VERSION..."
    TAG_MSG="Tagging version $FINAL_VERSION - $RELEASE_NAME release

$COMMIT_MESSAGE"
    svn cp "$SVN_URL/trunk" "$SVN_URL/tags/$FINAL_VERSION" -m "$TAG_MSG"
    
    echo ""
    echo "✅ Deployment completed successfully!"
    echo ""
    echo "📦 Summary:"
    echo "   Plugin: $PLUGIN_SLUG"
    echo "   Version: $CURRENT_VERSION → $FINAL_VERSION"
    echo "   Release Type: $RELEASE_NAME"
    echo "   SVN Tag: $SVN_URL/tags/$FINAL_VERSION"
    echo ""
else
    echo "❌ Deployment cancelled"
fi