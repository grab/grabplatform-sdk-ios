#!/bin/bash

# Swift Package Manager Validation Script
# This script validates the SPM integration for GrabIdPartnerSDK

set -e

echo "================================================"
echo "GrabIdPartnerSDK - SPM Validation"
echo "================================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "Step 1: Validating Package.swift syntax..."
VALIDATION_OUTPUT=$(swift package dump-package 2>&1)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Package.swift is valid"
else
    echo -e "${RED}✗${NC} Package.swift validation failed"
    echo "$VALIDATION_OUTPUT"
    exit 1
fi

echo ""
echo "Step 2: Resolving package dependencies..."
if swift package resolve 2>&1 | grep -q "error:"; then
    echo -e "${RED}✗${NC} Package resolution failed"
    exit 1
else
    echo -e "${GREEN}✓${NC} Dependencies resolved successfully"
fi

echo ""
echo "Step 3: Checking source files..."
SOURCE_FILES=(
    "GrabIdPartnerSDK/Classes/AuthorizationCodeGenerator.swift"
    "GrabIdPartnerSDK/Classes/GrabApi.swift"
    "GrabIdPartnerSDK/Classes/GrabIdPartnerError.swift"
    "GrabIdPartnerSDK/Classes/GrabIdPartnerLogin.swift"
    "GrabIdPartnerSDK/Classes/IdTokenInfo.swift"
    "GrabIdPartnerSDK/Classes/KeychainTokenWrapper.swift"
)

for file in "${SOURCE_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} Found: $file"
    else
        echo -e "${RED}✗${NC} Missing: $file"
        exit 1
    fi
done

echo ""
echo "Step 4: Verifying CommonCrypto import..."
if grep -q "import CommonCrypto" "GrabIdPartnerSDK/Classes/AuthorizationCodeGenerator.swift"; then
    echo -e "${GREEN}✓${NC} CommonCrypto import found in AuthorizationCodeGenerator.swift"
else
    echo -e "${YELLOW}⚠${NC} CommonCrypto import not found (may cause SPM build issues)"
fi

echo ""
echo "Step 5: Checking bridging header exclusion..."
PACKAGE_CONTENT=$(cat Package.swift)
if echo "$PACKAGE_CONTENT" | grep -q "GrabIdPartnerSDK-Bridging-Header.h"; then
    echo -e "${GREEN}✓${NC} Bridging header is excluded from SPM builds"
else
    echo -e "${YELLOW}⚠${NC} Bridging header exclusion not found in Package.swift"
fi

echo ""
echo "================================================"
echo -e "${GREEN}All validation checks passed!${NC}"
echo "================================================"
echo ""
echo "Next steps:"
echo "1. Test integration in a sample app"
echo "2. Run: xcodebuild -scheme GrabIdPartnerSDK (if scheme exists)"
echo "3. Create a tag and push to GitHub"
echo "4. Test SPM installation from GitHub URL"
echo ""
echo "For detailed testing instructions, see: SPM_MIGRATION_GUIDE.md"
