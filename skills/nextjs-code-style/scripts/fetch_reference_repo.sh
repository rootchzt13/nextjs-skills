#!/usr/bin/env bash
# Clone (or update) the reference repo into .reference/banking so the agent can read
# real source files instead of relying on summaries. Safe to run repeatedly.
set -euo pipefail

REPO_URL="https://github.com/adrianhajdin/banking.git"
TARGET_DIR="${1:-.reference/banking}"

if [ -d "$TARGET_DIR/.git" ]; then
  echo "Updating reference repo in $TARGET_DIR"
  git -C "$TARGET_DIR" pull --ff-only --quiet
else
  echo "Cloning reference repo into $TARGET_DIR"
  mkdir -p "$(dirname "$TARGET_DIR")"
  git clone --depth 1 --quiet "$REPO_URL" "$TARGET_DIR"
fi

# Keep the reference out of version control
if [ -f .gitignore ] && ! grep -qx '.reference/' .gitignore; then
  echo '.reference/' >> .gitignore
fi

echo
echo "Files worth reading first:"
for file in \
  components/HeaderBox.tsx \
  components/TotalBalanceBox.tsx \
  components/RecentTransactions.tsx \
  components/CustomInput.tsx \
  components/AuthForm.tsx \
  lib/actions/user.actions.ts \
  lib/actions/bank.actions.ts \
  lib/appwrite.ts \
  lib/utils.ts \
  "app/(root)/page.tsx" \
  types/index.d.ts \
  constants/index.ts \
  app/globals.css
do
  echo "  $TARGET_DIR/$file"
done
