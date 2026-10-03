#!/usr/bin/env bash
# Builds the Flutter web app on Vercel, which has no Flutter preinstalled.
# Expects SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY as project environment variables.
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.6}"
FLUTTER_DIR="$PWD/.flutter-sdk"

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  echo "Downloading Flutter $FLUTTER_VERSION"
  mkdir -p "$FLUTTER_DIR"
  curl -sSfL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    | tar -xJ -C "$FLUTTER_DIR" --strip-components=1
fi

git config --global --add safe.directory '*'
export PATH="$FLUTTER_DIR/bin:$PATH"
flutter --disable-analytics >/dev/null 2>&1 || true
flutter --version

: "${SUPABASE_URL:?Set SUPABASE_URL in the Vercel project settings}"
: "${SUPABASE_PUBLISHABLE_KEY:?Set SUPABASE_PUBLISHABLE_KEY in the Vercel project settings}"

flutter pub get
flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY"
