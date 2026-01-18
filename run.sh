#!/bin/bash
#
# Xim Docker Setup & Run Script (HTTP version)
#
# Usage:
#   ./run.sh "/path/to/your/FINAL FANTASY XI"
#
# This will:
#   1. Build the Docker image (first time only, or if source changed)
#   2. Start the container with your FFXI folder mounted
#   3. Xim will be available at http://localhost:8083
#
# For HTTPS support (required for Cache API on non-localhost), use:
#   ./run-https.sh "/path/to/your/FINAL FANTASY XI"
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FFXI_PATH="$1"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=============================${NC}"
echo -e "${GREEN}   Xim Docker Runner (HTTP)${NC}"
echo -e "${GREEN}=============================${NC}"
echo ""

# Check for FFXI path
if [ -z "$FFXI_PATH" ]; then
    echo -e "${RED}ERROR: Please provide the path to your FINAL FANTASY XI folder${NC}"
    echo ""
    echo "Usage: $0 \"/path/to/FINAL FANTASY XI\""
    echo ""
    echo "This should be the folder containing ROM/, ROM2/, ROM3/, sound/, etc."
    echo ""
    echo "Examples:"
    echo "  $0 /home/user/ffxi/FINAL\ FANTASY\ XI"
    echo "  $0 \"/mnt/games/FFXI/FINAL FANTASY XI\""
    echo "  $0 \"/home/user/.wine/drive_c/Program Files (x86)/PlayOnline/SquareEnix/FINAL FANTASY XI\""
    echo ""
    exit 1
fi

# Convert to absolute path
FFXI_PATH="$(cd "$FFXI_PATH" 2>/dev/null && pwd)" || {
    echo -e "${RED}ERROR: FFXI path does not exist: $1${NC}"
    exit 1
}

# Validate FFXI structure
if [ ! -d "$FFXI_PATH/ROM" ]; then
    echo -e "${RED}ERROR: Invalid FFXI folder - missing ROM/ subfolder${NC}"
    echo "Path checked: $FFXI_PATH"
    exit 1
fi

if [ ! -d "$FFXI_PATH/ROM/0" ]; then
    echo -e "${RED}ERROR: Invalid FFXI folder - ROM folder missing numbered subfolders (0/, 1/, etc.)${NC}"
    echo "Path checked: $FFXI_PATH/ROM"
    exit 1
fi

echo "FFXI Path: $FFXI_PATH"
echo ""

# Show what was found
echo "Found directories:"
for dir in ROM ROM2 ROM3 ROM4 ROM5 ROM6 ROM7 ROM8 ROM9 sound; do
    if [ -d "$FFXI_PATH/$dir" ]; then
        echo -e "  ${GREEN}✓${NC} $dir/"
    else
        echo -e "  ${YELLOW}✗${NC} $dir/ (not found - may be optional)"
    fi
done
echo ""

# Check for required source files
if [ ! -f "$SCRIPT_DIR/build.gradle.kts" ]; then
    echo -e "${RED}ERROR: Source files not found!${NC}"
    echo ""
    echo "Please extract the Xim source code into this directory."
    echo "Expected file: $SCRIPT_DIR/build.gradle.kts"
    echo ""
    exit 1
fi

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}ERROR: Docker is not installed${NC}"
    echo ""
    echo "Install Docker:"
    echo "  Ubuntu/Debian: sudo apt install docker.io docker-compose"
    echo "  Or: https://docs.docker.com/engine/install/"
    echo ""
    exit 1
fi

# Check if docker-compose exists, use 'docker compose' if not
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    echo -e "${RED}ERROR: docker-compose not found${NC}"
    echo "Install: sudo apt install docker-compose"
    exit 1
fi

cd "$SCRIPT_DIR"

# Export FFXI path for docker-compose
export XIM_FFXI_PATH="$FFXI_PATH"

# Persist XIM_FFXI_PATH to ~/.bashrc for future sessions
BASHRC_FILE="$HOME/.bashrc"
EXPORT_LINE="export XIM_FFXI_PATH=\"$FFXI_PATH\""

if grep -q "^export XIM_FFXI_PATH=" "$BASHRC_FILE" 2>/dev/null; then
    # Update existing entry
    sed -i "s|^export XIM_FFXI_PATH=.*|$EXPORT_LINE|" "$BASHRC_FILE"
    echo -e "${GREEN}Updated XIM_FFXI_PATH in ~/.bashrc${NC}"
else
    # Add new entry
    echo "" >> "$BASHRC_FILE"
    echo "# Xim FFXI path (added by run.sh)" >> "$BASHRC_FILE"
    echo "$EXPORT_LINE" >> "$BASHRC_FILE"
    echo -e "${GREEN}Added XIM_FFXI_PATH to ~/.bashrc${NC}"
fi
echo ""

# Check if image needs building
if ! docker image inspect xim:latest &> /dev/null; then
    echo -e "${YELLOW}Building Docker image (this takes a few minutes the first time)...${NC}"
    echo ""
    $COMPOSE_CMD build
    echo ""
fi

# Stop existing container if running
$COMPOSE_CMD down 2>/dev/null || true

# Start container
echo "Starting Xim..."
$COMPOSE_CMD up -d

echo ""
echo -e "${GREEN}=============================${NC}"
echo -e "${GREEN}   Xim is running!${NC}"
echo -e "${GREEN}=============================${NC}"
echo ""
echo "  URL:          http://localhost:8083"
echo "  Game Mode:    http://localhost:8083/?mode=game"
echo "  Asset Viewer: http://localhost:8083/"
echo ""

# Show network access
IP_ADDR=$(hostname -I 2>/dev/null | awk '{print $1}')
if [ -n "$IP_ADDR" ]; then
    echo -e "  ${YELLOW}Network:      http://$IP_ADDR:8083${NC}"
    echo -e "  ${YELLOW}NOTE: Cache API won't work over HTTP from other devices.${NC}"
    echo -e "  ${YELLOW}      Use run-https.sh for network access with caching.${NC}"
    echo ""
fi

echo "Commands:"
echo "  Stop:    $COMPOSE_CMD down"
echo "  Logs:    $COMPOSE_CMD logs -f"
echo "  Rebuild: $COMPOSE_CMD build --no-cache"
echo ""
