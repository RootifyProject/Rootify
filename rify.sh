#!/bin/bash
#
# Copyright (C) 2026 Rootify - Aby - FoxLabs
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Rootify Build & Run Wrapper
# Engineered for high-frequency development workflows.

check_environment() {
    echo "--- Checking Environment Health ---"
    
    # Check Flutter
    if ! command -v flutter &> /dev/null; then
        echo "Error: Flutter SDK not found in PATH."
        exit 1
    fi
    
    echo "Environment OK."
    echo "----------------------------------"
}

show_help() {
    echo "=========================================================="
    echo "       ROOTIFY CLI UTILITY - DEVELOPMENT TOOLKIT          "
    echo "=========================================================="
    echo "Usage: ./rify.sh [command] [context-flags] [mode-flags] [args]"
    echo ""
    echo "COMMANDS:"
    echo "  run                Execute the app on a target device/emulator."
    echo "                     - Default Mode: Debug (JIT) with Hot Reload."
    echo "                     - Supports: --debug, --profile, --release."
    echo ""
    echo "  build              Generate production-ready binaries."
    echo "                     - Logic: Release (AOT) with Full Optimization."
    echo "                     - Enforces: --split-per-abi for ARM architectures."
    echo "                     - Output: ~/Apps/[Context]/"
    echo ""
    echo "CONTEXT FLAGS (Maps to Gradle -Pctx=[context]):"
    echo "  -alpha             Internal testing. (Maps: -Palpha or -Pctx=alpha)"
    echo "  -beta              Feature testing.  (Maps: -Pbeta  or -Pctx=beta)"
    echo "  -rc                Release Candidate (Maps: -Prc    or -Pctx=rc)"
    echo "  -stable            Stable Production (Maps: -Pstable or -Pctx=stable)"
    echo ""
    echo "MODE SELECTION:"
    echo "  -d, --debug        Debug Mode   (Alternative: flutter run --debug)"
    echo "  -p, --profile      Profile Mode (Alternative: flutter run --profile)"
    echo "  -r, --release      Release Mode (Alternative: flutter run --release)"
    echo ""
    echo "MANUAL COMMAND EQUIVALENTS (See README.md for more):"
    echo "  # Run Beta build in Profile mode"
    echo "  flutter run --profile -Pctx=beta"
    echo "  # or: flutter run -profile -Pbeta"
    echo ""
    echo "  # Build Stable Production APKs"
    echo "  flutter build apk --release --split-per-abi -Pctx=stable"
    echo "  # or: flutter build apk --release -Pstable"
    echo ""
    echo "  # Standard Build Pattern"
    echo "  # Release Build (Without ctx)"
    echo "  flutter build apk --release"
    echo "  # or"
    echo "  flutter build apk -release"
    echo ""
    echo "  # Debug Build (Without ctx)"
    echo "  flutter build apk --debug"
    echo "  # or"
    echo "  flutter build apk -debug"
    echo ""
    echo "  # Profile Build (Without ctx)"
    echo "  flutter build apk --profile"
    echo "  # or"
    echo "  flutter build apk -profile"
    echo ""
    echo "ENVIRONMENT:"
    echo "  - Flutter SDK      Stable channel (v3.27.0+)"
    echo "  - JDK 17           Required for Gradle execution."
    echo "  - Signing          Load from key.properties (Optional fallback to debug)."
    echo ""
    echo "EXAMPLES:"
    echo "  ./rify.sh run -beta -p      # Run Beta build in Profile mode"
    echo "  ./rify.sh build -stable     # Build Stable production APKs"
    echo "  ./rify.sh -help            # Show this documentation"
    echo "=========================================================="
    exit 0
}

if [[ "$1" == "-help" || "$1" == "--help" || -z "$1" ]]; then
    show_help
fi

check_environment

CMD=$1
shift

FLAGS=""
FLUTTER_ARGS=""

for arg in "$@"; do
    case $arg in
        -alpha) FLAGS="$FLAGS -Pctx=alpha" ;;
        -beta)  FLAGS="$FLAGS -Pctx=beta" ;;
        -rc)    FLAGS="$FLAGS -Pctx=rc" ;;
        -stable) FLAGS="$FLAGS -Pctx=stable" ;;
        -p|--profile) FLUTTER_ARGS="$FLUTTER_ARGS --profile" ;;
        -d|--debug)   FLUTTER_ARGS="$FLUTTER_ARGS --debug" ;;
        -r|--release) FLUTTER_ARGS="$FLUTTER_ARGS --release" ;;
        *)            FLUTTER_ARGS="$FLUTTER_ARGS $arg" ;;
    esac
done

if [ "$CMD" == "run" ]; then
    echo "Executing Rootify Run ($FLAGS)..."
    flutter run $FLUTTER_ARGS $FLAGS
elif [ "$CMD" == "build" ]; then
    echo "Orchestrating Rootify Build ($FLAGS)..."
    flutter build apk --release --split-per-abi $FLUTTER_ARGS $FLAGS
else
    echo "Unknown command: $CMD"
    exit 1
fi
