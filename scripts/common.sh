#!/usr/bin/env bash

# =================================================================
# Common Utilities for Don's Scripts
# =================================================================
# Shared functions and constants used across all setup scripts.
# Source this file at the beginning of other scripts.
#
# Usage: source "$(dirname "$0")/scripts/common.sh"
# Or from scripts folder: source "$(dirname "$0")/common.sh"
# =================================================================

# Exit on any error
set -e

# Colors for output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export BOLD='\033[1m'
export NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "\n${BOLD}${BLUE}=== $1 ===${NC}"
}

# Utility functions
expand_path() {
    local path="$1"
    # Expand tilde to home directory
    path="${path/#\~/$HOME}"
    echo "$path"
}

resolve_path() {
    local path="$1"
    path=$(expand_path "$path")
    # Get absolute path
    if [[ -d "$path" ]]; then
        echo "$(cd "$path" && pwd)"
    elif [[ -f "$path" ]]; then
        echo "$(cd "$(dirname "$path")" && pwd)/$(basename "$path")"
    else
        echo "$path"
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if directory exists and is not empty
dir_not_empty() {
    [[ -d "$1" && -n "$(ls -A "$1" 2>/dev/null)" ]]
}

# Make script executable and run it
run_script() {
    local script_path="$1"
    if [[ -f "$script_path" ]]; then
        chmod +x "$script_path"
        "$script_path" "${@:2}"
    else
        log_error "Script not found: $script_path"
        return 1
    fi
}

# Get script directory (works from any location)
get_script_dir() {
    echo "$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
}

# Get project root directory
get_project_root() {
    local script_dir="$(get_script_dir)"
    if [[ "$(basename "$script_dir")" == "scripts" ]]; then
        echo "$(dirname "$script_dir")"
    else
        echo "$script_dir"
    fi
}

log_info "Common utilities loaded successfully"