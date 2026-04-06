#!/bin/bash
# THE IPA STORE - Startup Script
# Run this to start the server

export PORT=${PORT:-3000}
export NODE_ENV=production

echo "Starting THE IPA STORE server on port $PORT..."
node --enable-source-maps ./dist/index.mjs
