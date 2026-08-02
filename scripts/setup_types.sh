#!/bin/bash
# Exit on any error
set -e

# Change directory to the repository root (ensure the script runs from the correct relative path)
cd "$(dirname "$0")/.."

# Create types directory if not exists
mkdir -p .types

# Clean existing clone if present to avoid errors
if [ -d ".types/wow-api" ]; then
	rm -rf .types/wow-api
fi

echo "Cloning vscode-wow-api..."
# Sparse clone Ketho/vscode-wow-api
git clone --depth 1 --filter=blob:none --no-checkout https://github.com/Ketho/vscode-wow-api.git .types/wow-api
cd .types/wow-api
git sparse-checkout init --cone
git sparse-checkout set Annotations
git checkout
cd ../..

echo "Cloning FramexmlAnnotations..."
# Clean existing FrameXML annotations inside Annotations
rm -rf .types/wow-api/Annotations/FrameXML

# Clone FrameXML annotations
git clone --depth 1 https://github.com/NumyAddon/FramexmlAnnotations.git .types/wow-api/Annotations/FrameXML

echo "Setup complete!"
