# Get version from package.json
PACKAGE_VERSION=$(cat package.json | grep version | head -1 | awk -F: '{ print $2 }' | sed 's/[\",]//g' | tr -d '[[:space:]]')

# Remove default tag from npm version
git tag -d v$PACKAGE_VERSION

# Add unstaged files and commit
git add .
git commit --amend --no-edit
git tag $PACKAGE_VERSION
