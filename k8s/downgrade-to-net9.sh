#!/bin/bash

# Downgrade eShop from .NET 10 to .NET 9 (stable)
# The README states this is based on .NET 9, but projects were targeting net10.0

set -e

echo "=================================================="
echo "Downgrading eShop to .NET 9 (stable)"
echo "=================================================="
echo ""

ROOT_DIR="/Users/adarshkumar/Documents/demo/dotnet/eshop/eShop"

echo "Step 1: Updating global.json to .NET 9.0..."
cat > "$ROOT_DIR/global.json" <<'EOF'
{
  "sdk": {
    "version": "9.0.100",
    "rollForward": "latestFeature",
    "allowPrerelease": false
  },
  "test": {
    "runner": "Microsoft.Testing.Platform"
  },
  "msbuild-sdks": {
    "MSTest.Sdk": "4.0.2"
  }
}
EOF

echo "✓ Updated global.json"
echo ""

echo "Step 2: Updating all .csproj files from net10.0 to net9.0..."

# Find and update all csproj files
find "$ROOT_DIR/src" -name "*.csproj" -type f | while read -r csproj; do
    if grep -q "net10.0" "$csproj"; then
        echo "  Updating: $(basename $csproj)"
        sed -i '' 's/<TargetFramework>net10\.0<\/TargetFramework>/<TargetFramework>net9.0<\/TargetFramework>/g' "$csproj"
    fi
done

echo "✓ Updated all project files"
echo ""

echo "Step 3: Updating Dockerfiles to use .NET 9..."
# The build-and-push.sh script will generate these with .NET 9 images

echo "✓ Ready to build"
echo ""
echo "=================================================="
echo "✓ Downgrade complete!"
echo "=================================================="
echo ""
echo "Now you can build with stable .NET 9:"
echo "  cd k8s"
echo "  rm -rf dockerfiles/"
echo "  ./build-and-push.sh"
