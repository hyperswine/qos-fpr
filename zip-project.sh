#!/usr/bin/env bash
# zip-project.sh
# Zips the current directory, excluding common build artifacts and build directories.
#
# Usage:
#   ./zip-project.sh                 # creates <dir>_YYYYMMDD_HHMMSS.zip
#   ./zip-project.sh my-archive.zip  # uses the name you provide

set -euo pipefail

# Determine archive name
if [ $# -ge 1 ]; then
  ARCHIVE_NAME="$1"
else
  PROJECT_NAME="$(basename "$(pwd)")"
  TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  ARCHIVE_NAME="${PROJECT_NAME}_${TIMESTAMP}.zip"
fi

echo "Creating archive: $ARCHIVE_NAME"
echo "Excluding build directories and build artifacts..."

# Build exclusion list (patterns for zip -x)
EXCLUDES=(
  # Common build directories
  "build" "build/*" "*/build" "*/build/*"
  "target" "target/*" "*/target" "*/target/*"
  "dist-newstyle" "dist-newstyle/*" "*/dist-newstyle" "*/dist-newstyle/*"
  "dist" "dist/*" "*/dist" "*/dist/*"
  ".build" ".build/*" "*/.build" "*/.build/*"
  "out" "out/*" "*/out" "*/out/*"
  "_build" "_build/*" "*/_build" "*/_build/*"
  "cmake-build-*" "*/cmake-build-*"

  # Project-specific generated files (from Makefile + .gitignore)
  "fprc" "*/fprc"
  "*.elf"
  "apps/*.qa"
  "runtime/apps_data.c"
  "disk.img"
  ".git/*"
  ".vscode/*"
  "*.hi"
  "*.o"
  "cabal.project.local"
)

# Convert to -x arguments
ZIP_ARGS=()
for pat in "${EXCLUDES[@]}"; do
  ZIP_ARGS+=( -x "$pat" )
done

zip -r "$ARCHIVE_NAME" . "${ZIP_ARGS[@]}"

echo "✓ Created $ARCHIVE_NAME (build artifacts excluded)"
