#!/bin/bash

# Automated SPM Test Setup Script
# This script creates a test Xcode project and configures it for SPM testing

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  GrabIdPartnerSDK - SPM Integration Test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SDK_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECT_NAME="SPMTestApp"
PROJECT_DIR="$SCRIPT_DIR/XcodeProject"

echo -e "${BLUE}Configuration:${NC}"
echo "  SDK Root: $SDK_ROOT"
echo "  Test App: $PROJECT_DIR"
echo ""

# Step 1: Validate SPM Package
echo -e "${BLUE}[1/5] Validating SPM Package...${NC}"
cd "$SDK_ROOT"
if swift package dump-package > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Package.swift is valid"
else
    echo -e "${RED}✗${NC} Package.swift validation failed"
    exit 1
fi

# Step 2: Create project directory
echo ""
echo -e "${BLUE}[2/5] Setting up project directory...${NC}"
if [ -d "$PROJECT_DIR" ]; then
    echo -e "${YELLOW}⚠${NC} Project directory exists. Remove it? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        rm -rf "$PROJECT_DIR"
        echo -e "${GREEN}✓${NC} Removed existing project"
    else
        echo -e "${YELLOW}⚠${NC} Using existing project"
    fi
fi

# Step 3: Check if Xcode is available
echo ""
echo -e "${BLUE}[3/5] Checking Xcode installation...${NC}"
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}✗${NC} Xcode not found. Please install Xcode first."
    exit 1
fi
echo -e "${GREEN}✓${NC} Xcode found: $(xcodebuild -version | head -1)"

# Step 4: Manual instructions (Xcode project creation must be manual)
echo ""
echo -e "${BLUE}[4/5] Creating Xcode Project...${NC}"
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  MANUAL STEP REQUIRED${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo ""
echo "Please create a new Xcode project manually:"
echo ""
echo "1. Open Xcode"
echo "2. File > New > Project"
echo "3. Choose: iOS > App"
echo "4. Configure:"
echo "   • Product Name: $PROJECT_NAME"
echo "   • Interface: Storyboard"
echo "   • Language: Swift"
echo "   • Location: $SCRIPT_DIR/"
echo ""
echo "5. After creation, return here and press ENTER"
echo ""
read -p "Press ENTER after creating the Xcode project..."

# Check if project was created
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}✗${NC} Project not found at $PROJECT_DIR"
    echo "Please create the project and try again."
    exit 1
fi

echo -e "${GREEN}✓${NC} Project directory found"

# Step 5: Instructions for adding package
echo ""
echo -e "${BLUE}[5/5] Package Integration Instructions${NC}"
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  FOLLOW THESE STEPS IN XCODE${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo ""
echo "1. Open project: $PROJECT_DIR/$PROJECT_NAME.xcodeproj"
echo ""
echo "2. Add GrabIdPartnerSDK Package:"
echo "   a. Project Navigator > Select Project"
echo "   b. Select $PROJECT_NAME target"
echo "   c. General tab > Frameworks, Libraries, and Embedded Content"
echo "   d. Click '+' > Add Package Dependency..."
echo "   e. Click 'Add Local...'"
echo "   f. Navigate to: $SDK_ROOT"
echo "   g. Click 'Add Package'"
echo "   h. Ensure 'GrabIdPartnerSDK' is checked"
echo "   i. Click 'Add Package'"
echo ""
echo "3. Replace files:"
echo "   a. ViewController.swift → Copy content from:"
echo "      $SCRIPT_DIR/TestViewController.swift"
echo ""
echo "   b. AppDelegate.swift → Copy content from:"
echo "      $SCRIPT_DIR/TestAppDelegate.swift"
echo ""
echo "4. Configure Info.plist:"
echo "   Add the GrabIdPartnerSDK configuration from:"
echo "   $SCRIPT_DIR/Info.plist.template"
echo ""
echo "5. Build and Run:"
echo "   • Press Cmd+B to build"
echo "   • Press Cmd+R to run"
echo "   • Tap 'Test SDK Initialization' button"
echo ""
echo -e "${GREEN}Expected Result:${NC}"
echo "  Console should show:"
echo "  ✅ SDK initialized successfully"
echo "  ✅ Configuration loaded from Info.plist"
echo "  ✅ SPM Integration Test: PASSED"
echo ""

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}Setup Complete!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next: Open Xcode and follow the steps above ⬆️"
echo ""
echo "Documentation:"
echo "  • Full Guide: $SCRIPT_DIR/README.md"
echo "  • Quick Test: $SCRIPT_DIR/QUICK_TEST.md"
echo ""
