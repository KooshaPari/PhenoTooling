#!/usr/bin/env bash
# build.sh - Compile the Phinbox inbox-helper Swift binary
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
OUTPUT_DIR="${REPO_ROOT}/target/release"
OUTPUT="${OUTPUT_DIR}/inbox-helper"

echo "Building inbox-helper..."
echo "  Source: ${SCRIPT_DIR}/main.swift"
echo "  Output: ${OUTPUT}"

mkdir -p "${OUTPUT_DIR}"

swiftc \
    -o "${OUTPUT}" \
    "${SCRIPT_DIR}/main.swift" \
    -framework Cocoa \
    -framework WebKit \
    -parse-as-library \
    -O \
    -whole-module-optimization

# Make executable
chmod +x "${OUTPUT}"

echo "Build succeeded: ${OUTPUT}"
echo "Run with: ${OUTPUT}"
