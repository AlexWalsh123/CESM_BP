#!/bin/bash
#
# Script to update CIME from externals while preserving local configuration changes
# This script:
# 1. Creates a temporary backup of current CIME
# 2. Checks out the official CIME version
# 3. Restores custom machine configurations and other local changes
# 4. Cleans up the temporary backup
#

set -e  # Exit on error

CESM_ROOT="/user/home/xz20153/CESM_BP"
BACKUP_DIR="${CESM_ROOT}/cime_temp_backup_$(date +%Y%m%d_%H%M%S)"
CIME_DIR="${CESM_ROOT}/cime"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== CIME Update Script with Config Preservation ===${NC}"
echo ""

# Step 1: Check if CIME exists
if [ ! -d "$CIME_DIR" ]; then
    echo -e "${RED}Error: CIME directory not found at $CIME_DIR${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 1: Creating temporary backup of current CIME...${NC}"
cp -r "$CIME_DIR" "$BACKUP_DIR"
echo -e "${GREEN}✓ Backup created at: $BACKUP_DIR${NC}"
echo ""

# Step 2: Identify files to preserve
echo -e "${YELLOW}Step 2: Identifying custom configuration files...${NC}"
PRESERVE_FILES=(
    "config/cesm/machines/config_machines.xml"
    "config/cesm/machines/config_batch.xml"
    "config/cesm/machines/config_compilers.xml"
    "config/cesm/machines/config_pio.xml"
    "config/cesm/machines/config_workflow.xml"
    "config/cesm/config_inputdata.xml"
)

# Check which files actually have changes
CHANGED_FILES=()
for file in "${PRESERVE_FILES[@]}"; do
    if [ -f "$BACKUP_DIR/$file" ]; then
        CHANGED_FILES+=("$file")
        echo "  - Found: $file"
    fi
done
echo ""

# Step 3: Remove current CIME
echo -e "${YELLOW}Step 3: Removing current CIME directory...${NC}"
rm -rf "$CIME_DIR"
echo -e "${GREEN}✓ CIME directory removed${NC}"
echo ""


# Step 5: Checkout official CIME
echo -e "${YELLOW}Step 5: Checking out official CIME from externals...${NC}"
module load languages/python/3.8.20
module load subversion/1.14.2-zx34
cd "$CESM_ROOT"
python3 ./manage_externals/checkout_externals 2>&1 | grep -E "(Checking out|Processing|Error|ERROR)" || true
echo -e "${GREEN}✓ Official CIME checked out${NC}"
echo ""

# Step 6: Restore custom configuration files
echo -e "${YELLOW}Step 6: Restoring custom configuration files...${NC}"
for file in "${CHANGED_FILES[@]}"; do
    if [ -f "$BACKUP_DIR/$file" ]; then
        echo "  Restoring: $file"
        cp "$BACKUP_DIR/$file" "$CIME_DIR/$file"
    fi
done
echo -e "${GREEN}✓ Custom configurations restored${NC}"
echo ""

# Step 7: Make scripts executable
echo -e "${YELLOW}Step 7: Making CIME scripts executable...${NC}"
chmod +x "$CIME_DIR/scripts/create_newcase"
chmod +x "$CIME_DIR/scripts/query_config"
echo -e "${GREEN}✓ Scripts made executable${NC}"
echo ""

# Step 8: Verify critical files
echo -e "${YELLOW}Step 8: Verifying installation...${NC}"
VERIFY_FILES=(
    "src/components/data_comps_mct/docn/cime_config/config_component.xml"
    "config/cesm/machines/config_machines.xml"
    "scripts/create_newcase"
)

ALL_GOOD=true
for file in "${VERIFY_FILES[@]}"; do
    if [ -f "$CIME_DIR/$file" ]; then
        echo -e "  ${GREEN}✓${NC} $file"
    else
        echo -e "  ${RED}✗${NC} $file - MISSING!"
        ALL_GOOD=false
    fi
done
echo ""

# Step 9: Check for bluepebble machine
echo -e "${YELLOW}Step 9: Verifying bluepebble machine configuration...${NC}"
if grep -q "bluepebble" "$CIME_DIR/config/cesm/machines/config_machines.xml"; then
    echo -e "${GREEN}✓ bluepebble machine configuration present${NC}"
else
    echo -e "${RED}✗ WARNING: bluepebble machine configuration NOT found!${NC}"
    ALL_GOOD=false
fi
echo ""

# Step 10: Clean up or keep backup
if [ "$ALL_GOOD" = true ]; then
    echo -e "${YELLOW}Step 10: Cleaning up temporary backup...${NC}"
    read -p "Delete temporary backup at $BACKUP_DIR? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$BACKUP_DIR"
        echo -e "${GREEN}✓ Temporary backup removed${NC}"
    else
        echo -e "${YELLOW}! Keeping backup at: $BACKUP_DIR${NC}"
    fi
else
    echo -e "${RED}! Keeping backup due to verification issues at: $BACKUP_DIR${NC}"
fi
echo ""

echo -e "${GREEN}=== CIME Update Complete ===${NC}"
echo ""
echo "You can now test case creation with:"
echo "  cd $CESM_ROOT"
echo "  ./cime/scripts/create_newcase --case ../CESM_cases/newtest --compset FWsc2000climo --res f09_f09_mg17 --project XXXXXXXX"
