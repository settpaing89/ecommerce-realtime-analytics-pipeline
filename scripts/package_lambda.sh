#!/bin/bash

# Optimized Lambda packaging script

set -e

echo "📦 Packaging Lambda function..."

# Create temp directory
PACKAGE_DIR=$(mktemp -d)
echo "Temp directory: $PACKAGE_DIR"

# Copy Lambda function
echo "Copying lambda_function.py..."
cp src/ingestion/lambda_function.py $PACKAGE_DIR/

# Install only necessary dependencies
echo "Installing dependencies (this may take a minute)..."

# Only install small dependencies not in the layer if needed
# AWS SDK Layer covers pandas, pyarrow, numpy
# Requests is usually needed if not in typical layers, but let's check
# For now, we only need what's NOT in the layer.
# The layer is AWSSDKPandas-Python311.

# If we have other dependencies in requirements.txt that are NOT in the layer, we should install them.
# But for now, specifically removing the big ones.

# Note: Ideally we should parse requirements.txt, but for this specific optimization task
# we are manually removing the heavy hitters.

# No extra pip install needed for this specific function as per current requirements
# provided they are all in the layer or standard lib.
# checking requirements.txt again...
# python-dotenv, pyyaml, faker, great-expectations... might be needed if used in lambda.
# Lambda imports: json, boto3, pandas, datetime, io, os, logging.
# pandas -> Layer. boto3 -> Runtime. json, datetime, io, os, logging -> Stdlib.

# So actually, we don't need ANY pip install for the current lambda_function.py imports!
echo "No extra dependencies to install (using Layers)"

# Remove unnecessary files
echo "Cleaning up unnecessary files..."
cd $PACKAGE_DIR

# Remove test files
find . -type d -name "tests" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name "*.dist-info" -exec rm -rf {} + 2>/dev/null || true

# Remove __pycache__
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete
find . -type f -name "*.pyo" -delete

# Remove docs and examples
find . -type d -name "examples" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name "docs" -exec rm -rf {} + 2>/dev/null || true

# Create zip file
echo "Creating zip file..."
zip -r9 -q lambda_function.zip . -x "*.pyc" -x "*__pycache__*" -x "*.dist-info/*"

# Move to project root
mv lambda_function.zip $OLDPWD/

cd $OLDPWD

# Cleanup
rm -rf $PACKAGE_DIR

# Get size
SIZE=$(du -h lambda_function.zip | awk '{print $1}')
echo "✅ Package created: lambda_function.zip ($SIZE)"

# Verify size
SIZE_MB=$(du -m lambda_function.zip | awk '{print $1}')
if [ "$SIZE_MB" -gt 50 ]; then
    echo "⚠️  Warning: Package is ${SIZE_MB}MB, larger than expected (~15-20MB)"
    echo "   Lambda deployment limit is 250MB unzipped, 50MB zipped"
    echo "   This should still work, but consider optimization"
else
    echo "✅ Size is good: ${SIZE_MB}MB"
fi

echo ""
echo "Package contents:"
unzip -l lambda_function.zip | head -20
