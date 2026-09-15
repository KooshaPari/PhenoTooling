#!/bin/bash
# Start the evaluation results API server
# Usage: ./start_api.sh [port]

PORT=${1:-8080}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting evaluation results API server..."
cd "$SCRIPT_DIR"
python3 api.py --port "$PORT"
