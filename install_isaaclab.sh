#!/bin/bash
# ============================================================================
# One-click Installation Script for IsaacSim and IsaacLab (pip only)
# Supports: conda / uv package managers
# Versions: v3.0.0 (release/3.0.0), v1.4.1, v2.3.2, main, develop (extensible)
# ============================================================================
# Version: v3.0.2
# Author: Ziqi Fan
# Email: fanziqi614@gmail.com
# GitHub: https://github.com/fan-ziqi
# CN Document: https://docs.robotsfan.com/isaaclab
# Feedback: https://github.com/fan-ziqi/IsaacLab/issues
# ============================================================================

set -e

# --- Color codes ---
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
# shellcheck disable=SC2034
BLUE='\033[1;37m'
CYAN='\033[1;36m'
BOLD='\033[1m'
RESET='\033[0m'

# --- Helper functions ---

divider() {
    echo -e "\n${CYAN}-------------------------------------------------------${RESET}\n"
}

print_author_info() {
    echo -e "${BOLD}One-click Installation Script for IsaacSim and IsaacLab (pip only)${RESET}"
    echo "Version: v3.0.2"
    echo "Author: Ziqi Fan"
    echo "Email: fanziqi614@gmail.com"
    echo "GitHub: https://github.com/fan-ziqi"
    echo "CN Document: https://docs.robotsfan.com/isaaclab"
    echo "Feedback: https://github.com/fan-ziqi/IsaacLab/issues"
}

error_handler() {
    echo -e "${RED}An error occurred during the execution of the script.${RESET}"
    echo -e "Please check the error message above and re-run the script after resolving the issue."
    exit 1
}

trap 'error_handler' ERR

# Ask y/n question, sets global ANSWER to "y" or "n"
ask_yn() {
    local prompt="$1"
    while true; do
        read -r -p "$prompt (y/n): " ANSWER
        case "$ANSWER" in
            y|n) return ;;
            *) echo -e "${RED}Invalid input. Please enter 'y' or 'n'.${RESET}" ;;
        esac
    done
}

# Ask user to select from a numbered list, sets global SELECTION
# Usage: ask_choice "prompt" max [default]
ask_choice() {
    local prompt="$1"
    local max="$2"
    local default="${3:-}"
    while true; do
        if [ -n "$default" ]; then
            read -r -p "$prompt [1-$max] (default: $default): " SELECTION
            SELECTION="${SELECTION:-$default}"
        else
            read -r -p "$prompt [1-$max]: " SELECTION
        fi
        if [[ "$SELECTION" =~ ^[0-9]+$ ]] && [ "$SELECTION" -ge 1 ] && [ "$SELECTION" -le "$max" ]; then
            return
        fi
        echo -e "${RED}Invalid input. Please enter a number between 1 and $max.${RESET}"
    done
}

# Ask user for a non-empty string, sets global INPUT_VALUE
ask_required() {
    local prompt="$1"
    while true; do
        read -r -p "$prompt: " INPUT_VALUE
        if [ -n "$INPUT_VALUE" ]; then
            return
        fi
        echo -e "${RED}Input cannot be empty. Please try again.${RESET}"
    done
}

check_environment_python() {
    local environment_python
    environment_python=$(python --version)
    if [[ "$environment_python" != "Python $PYTHON_VER."* ]]; then
        echo -e "${RED}The selected environment requires Python $PYTHON_VER, but has $environment_python.${RESET}"
        exit 1
    fi
}

# ============================================================================
# Version Configuration Table
# To add a new version, add entries to each array below.
# ============================================================================

declare -A VERSION_PYTHON VERSION_PYTORCH VERSION_TORCHVISION VERSION_ISAACSIM VERSION_ISAACSIM_VER VERSION_ISAACSIM_EXTRA_FLAGS VERSION_GIT_TAG VERSION_CUDA

# --- v3.0.0 ---
VERSION_PYTHON[v3.0.0]="3.12"
VERSION_PYTORCH[v3.0.0]="2.11.0"
VERSION_TORCHVISION[v3.0.0]="torchvision==0.26.0"
VERSION_ISAACSIM[v3.0.0]="isaacsim[all,extscache]==6.1.0.0"
VERSION_ISAACSIM_VER[v3.0.0]="6.1.0.0"
VERSION_ISAACSIM_EXTRA_FLAGS[v3.0.0]=""
VERSION_GIT_TAG[v3.0.0]="release/3.0.0"
VERSION_CUDA[v3.0.0]="cu130"

# --- v1.4.1 ---
VERSION_PYTHON[v1.4.1]="3.10"
VERSION_PYTORCH[v1.4.1]="2.4.0"
VERSION_TORCHVISION[v1.4.1]=""
VERSION_ISAACSIM[v1.4.1]="isaacsim==4.2.0.2 isaacsim-extscache-physics==4.2.0.2 isaacsim-extscache-kit==4.2.0.2 isaacsim-extscache-kit-sdk==4.2.0.2"
VERSION_ISAACSIM_VER[v1.4.1]="4.2.0.2"
VERSION_ISAACSIM_EXTRA_FLAGS[v1.4.1]=""
VERSION_GIT_TAG[v1.4.1]="v1.4.1"
VERSION_CUDA[v1.4.1]="cu118"

# --- v2.3.2 ---
VERSION_PYTHON[v2.3.2]="3.11"
VERSION_PYTORCH[v2.3.2]="2.7.0"
VERSION_TORCHVISION[v2.3.2]="torchvision==0.22.0"
VERSION_ISAACSIM[v2.3.2]="isaacsim[all,extscache]==5.1.0"
VERSION_ISAACSIM_VER[v2.3.2]="5.1.0"
VERSION_ISAACSIM_EXTRA_FLAGS[v2.3.2]=""
VERSION_GIT_TAG[v2.3.2]="v2.3.2"
VERSION_CUDA[v2.3.2]="cu128"

# --- main ---
VERSION_PYTHON[main]="3.11"
VERSION_PYTORCH[main]="2.7.0"
VERSION_TORCHVISION[main]="torchvision==0.22.0"
VERSION_ISAACSIM[main]="isaacsim[all,extscache]"
VERSION_ISAACSIM_VER[main]="5.1.0"
VERSION_ISAACSIM_EXTRA_FLAGS[main]=""
VERSION_GIT_TAG[main]="main"
VERSION_CUDA[main]="cu128"

# --- develop ---
VERSION_PYTHON[develop]="3.12"
VERSION_PYTORCH[develop]="2.10.0"
VERSION_TORCHVISION[develop]="torchvision==0.25.0"
VERSION_ISAACSIM[develop]="isaacsim[all,extscache]==6.0.0"
VERSION_ISAACSIM_VER[develop]="6.0.0"
VERSION_ISAACSIM_EXTRA_FLAGS[develop]="--index-strategy unsafe-best-match --prerelease=allow"
VERSION_GIT_TAG[develop]="develop"
VERSION_CUDA[develop]="cu128"

# Map menu index to version key
VERSION_KEYS=("v3.0.0" "develop" "main" "v2.3.2" "v1.4.1")
VERSION_LABELS=()
for key in "${VERSION_KEYS[@]}"; do
    VERSION_LABELS+=("${key} (IsaacSim ${VERSION_ISAACSIM_VER[$key]}, Python ${VERSION_PYTHON[$key]}, PyTorch ${VERSION_PYTORCH[$key]}, ${VERSION_CUDA[$key]})")
done

# ============================================================================
# Step 0: Select IsaacLab Version
# ============================================================================

divider
print_author_info
divider

echo -e "${CYAN}[Step 0] Select IsaacLab version${RESET}\n"

for i in "${!VERSION_LABELS[@]}"; do
    echo -e "  ${BOLD}$((i+1))${RESET}) ${VERSION_LABELS[$i]}"
done
echo ""

ask_choice "Please select the IsaacLab version" "${#VERSION_KEYS[@]}" "1"
SELECTED_VERSION="${VERSION_KEYS[$((SELECTION-1))]}"

PYTHON_VER="${VERSION_PYTHON[$SELECTED_VERSION]}"
PYTORCH_VER="${VERSION_PYTORCH[$SELECTED_VERSION]}"
TORCHVISION_VER="${VERSION_TORCHVISION[$SELECTED_VERSION]}"
ISAACSIM_PKGS="${VERSION_ISAACSIM[$SELECTED_VERSION]}"
ISAACSIM_EXTRA_FLAGS="${VERSION_ISAACSIM_EXTRA_FLAGS[$SELECTED_VERSION]}"
GIT_TAG="${VERSION_GIT_TAG[$SELECTED_VERSION]}"
CUDA_VER="${VERSION_CUDA[$SELECTED_VERSION]}"

echo -e "\n${GREEN}Selected: IsaacLab ${BOLD}$SELECTED_VERSION${RESET}${GREEN} (Python $PYTHON_VER, PyTorch $PYTORCH_VER, $CUDA_VER)${RESET}"

divider

# ============================================================================
# Step 1: Select Package Manager
# ============================================================================

echo -e "${CYAN}[Step 1] Select package manager${RESET}\n"

# IsaacLab 3.0.0, main, and develop support uv.
if [[ "$SELECTED_VERSION" == "v3.0.0" || "$SELECTED_VERSION" == "main" || "$SELECTED_VERSION" == "develop" ]]; then
    echo -e "  ${BOLD}1${RESET}) uv (faster, recommended)"
    echo -e "  ${BOLD}2${RESET}) conda (Miniconda)"
    echo ""

    ask_choice "Please select the package manager" "2" "1"
    PKG_MANAGER="$([ "$SELECTION" == "1" ] && echo "uv" || echo "conda")"
else
    echo -e "${YELLOW}Version '$SELECTED_VERSION' only supports conda.${RESET}\n"
    PKG_MANAGER="conda"
fi

echo -e "\n${GREEN}Selected: ${BOLD}$PKG_MANAGER${RESET}"

INSTALL_BACKEND="isaacsim"
if [[ "$SELECTED_VERSION" == "v3.0.0" ]]; then
    echo -e "\n${CYAN}Select installation backend${RESET}\n"
    echo -e "  ${BOLD}1${RESET}) IsaacSim (full workflow)"
    echo -e "  ${BOLD}2${RESET}) Newton (without Isaac Sim)"
    echo ""
    ask_choice "Please select the installation backend" "2" "1"
    if [[ "$SELECTION" == "2" ]]; then INSTALL_BACKEND="newton"; fi
    echo -e "\n${GREEN}Selected: ${BOLD}$INSTALL_BACKEND${RESET}"
fi

divider

# ============================================================================
# Step 2: System Preparation
# ============================================================================

echo -e "${CYAN}[Step 2] System preparation${RESET}\n"

if [[ "$(uname -s)" != "Linux" ]]; then
    echo -e "${RED}This script supports Linux only.${RESET}"
    exit 1
fi

# Install system dependencies (allow failure if already installed)
echo -e "${CYAN}Installing system dependencies...${RESET}"
sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test 2>/dev/null || true
sudo apt-get update -qq
sudo apt-get install -y cmake build-essential git wget curl g++-11

divider

# --- Step 2a: Check NVIDIA GPU ---
echo -e "${CYAN}[Step 2a] Checking for NVIDIA GPU and drivers...${RESET}\n"

if ! command -v nvidia-smi &> /dev/null; then
    echo -e "${RED}NVIDIA drivers are not installed or not found.${RESET}"
    echo -e "Please install the latest NVIDIA GPU drivers before proceeding."
    echo -e "Visit ${CYAN}https://www.nvidia.com/Download/index.aspx${RESET} for instructions."
    exit 1
fi

echo -e "${GREEN}NVIDIA drivers detected:${RESET}"
nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader

# Compare versions: returns 0 if $1 >= $2.
version_ge() {
    printf '%s\n' "$2" "$1" | sort -V | head -n 1 | grep -Fqx "$2"
}

if [[ "$SELECTED_VERSION" == "v3.0.0" ]]; then
    driver_versions=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader)
    if [[ -z "$driver_versions" ]]; then
        echo -e "${RED}No NVIDIA GPU detected.${RESET}"
        exit 1
    fi
    while IFS= read -r driver_version; do
        if ! version_ge "$driver_version" "580.65.06"; then
            echo -e "${RED}IsaacLab 3.0.0 (CUDA 13.0) requires NVIDIA driver >= 580.65.06.${RESET}"
            exit 1
        fi
    done <<< "$driver_versions"
fi

divider

# --- Step 2b: Check GLIBC ---
echo -e "${CYAN}[Step 2b] Checking GLIBC version...${RESET}\n"

required_version="2.34"
if [[ "$SELECTED_VERSION" == "v3.0.0" || "$SELECTED_VERSION" == "v2.3.2" ]]; then
    required_version="2.35"
fi

if ! command -v ldd &> /dev/null; then
    echo -e "${RED}ldd not found. Cannot check GLIBC version.${RESET}"
    exit 1
fi

glibc_version=$(ldd --version | head -n 1 | awk '{print $NF}')
echo -e "Detected GLIBC version: ${CYAN}$glibc_version${RESET} (required: >= $required_version)"

if ! version_ge "$glibc_version" "$required_version"; then
    echo -e "${RED}GLIBC version $glibc_version does not meet the requirement (>= $required_version).${RESET}"
    echo -e "${RED}!!! Upgrading GLIBC is risky and may cause system instability !!!${RESET}"

    ask_yn "Do you want to proceed with the GLIBC upgrade?"
    if [[ "$ANSWER" != "y" ]]; then
        echo -e "${YELLOW}Exiting installation.${RESET}"
        exit 1
    fi

    echo -e "${YELLOW}Backing up and updating /etc/apt/sources.list...${RESET}"
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak

    CODENAME=$(lsb_release -cs)
    echo "deb http://archive.ubuntu.com/ubuntu ${CODENAME} main" | sudo tee -a /etc/apt/sources.list
    sudo apt-get update -qq
    sudo apt-get install -y libc6

    updated_version=$(ldd --version | head -n 1 | awk '{print $NF}')
    if ! version_ge "$updated_version" "$required_version"; then
        echo -e "${RED}Failed to upgrade GLIBC. Restoring sources.list...${RESET}"
        sudo mv /etc/apt/sources.list.bak /etc/apt/sources.list
        sudo apt-get update -qq
        exit 1
    fi

    sudo mv /etc/apt/sources.list.bak /etc/apt/sources.list
    sudo apt-get update -qq
    echo -e "${GREEN}GLIBC upgraded to $updated_version.${RESET}"
else
    echo -e "${GREEN}GLIBC version $glibc_version meets the requirement.${RESET}"
fi

divider

# ============================================================================
# Step 3: Setup Package Manager & Create Environment
# ============================================================================

echo -e "${CYAN}[Step 3] Setup $PKG_MANAGER and create environment${RESET}\n"

# Do not let an inherited environment override the one selected below.
unset VIRTUAL_ENV CONDA_PREFIX CONDA_DEFAULT_ENV UV_PROJECT_ENVIRONMENT UV_PYTHON PYTHONPATH

if [ "$PKG_MANAGER" == "uv" ]; then
    # --- uv path ---
    if ! command -v uv &> /dev/null; then
        echo -e "${YELLOW}uv is not installed. Installing...${RESET}"
        curl -LsSf https://astral.sh/uv/install.sh | sh
        # shellcheck disable=SC1091
        source "$HOME/.local/bin/env" 2>/dev/null || export PATH="$HOME/.local/bin:$PATH"
    else
        echo -e "${GREEN}uv is already installed.${RESET}"
    fi

    uv --version

    echo ""
    echo -e "${CYAN}uv virtual environments are stored in ~/.venvs/${RESET}"
    ask_required "Please enter the environment name"

    ENV_NAME="$INPUT_VALUE"
    if [[ ! "$ENV_NAME" =~ ^[A-Za-z0-9_][A-Za-z0-9_-]*$ || "$ENV_NAME" == "base" ]]; then
        echo -e "${RED}Invalid environment name. Use letters, numbers, underscores, or hyphens; do not use base.${RESET}"
        exit 1
    fi
    ENV_PATH="$HOME/.venvs/$ENV_NAME"

    if [ -d "$ENV_PATH" ]; then
        echo -e "${YELLOW}Environment '$ENV_NAME' already exists at $ENV_PATH.${RESET}"
        ask_yn "Do you want to delete and recreate it?"
        if [[ "$ANSWER" == "y" ]]; then
            rm -rf "$ENV_PATH"
            echo -e "${YELLOW}Deleted existing environment.${RESET}"
        else
            echo -e "${YELLOW}Using existing environment.${RESET}"
        fi
    fi

    if [ ! -d "$ENV_PATH" ]; then
        echo -e "${GREEN}Creating uv environment '$ENV_NAME' with Python $PYTHON_VER...${RESET}"
        uv venv --python "$PYTHON_VER" --python-preference only-managed --seed "$ENV_PATH"
    fi

    echo -e "${GREEN}Activating environment...${RESET}"
    # shellcheck disable=SC1091
    source "$ENV_PATH/bin/activate"
    check_environment_python

    echo -e "${CYAN}Upgrading pip...${RESET}"
    uv pip install --upgrade pip

else
    # --- conda path ---
    CONDA_DIR="$HOME/miniconda3"

    if ! command -v conda &> /dev/null; then
        echo -e "${YELLOW}Conda is not installed. Installing Miniconda...${RESET}"
        mkdir -p "$CONDA_DIR"
        CONDA_SCRIPT="${CONDA_DIR}/miniconda.sh"
        wget -q "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" -O "$CONDA_SCRIPT"
        bash "$CONDA_SCRIPT" -b -u -p "$CONDA_DIR"
        # shellcheck disable=SC1091
        source "${CONDA_DIR}/bin/activate"
        conda init --all
        echo "export PATH=\"${CONDA_DIR}/bin:\$PATH\"" >> ~/.bashrc
        conda config --set auto_activate_base false
        # shellcheck disable=SC1090
        source ~/.bashrc 2>/dev/null || true
    else
        echo -e "${GREEN}Conda is already installed.${RESET}"
    fi

    conda config --add channels conda-forge 2>/dev/null || true
    conda config --set channel_priority strict
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main 2>/dev/null || true
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r 2>/dev/null || true

    echo ""
    ask_required "Please enter the Conda environment name (e.g., isaaclab-v2)"

    ENV_NAME="$INPUT_VALUE"
    if [[ ! "$ENV_NAME" =~ ^[A-Za-z0-9_][A-Za-z0-9_-]*$ || "$ENV_NAME" == "base" ]]; then
        echo -e "${RED}Invalid environment name. Use letters, numbers, underscores, or hyphens; do not use base.${RESET}"
        exit 1
    fi

    if conda env list | grep -q "^$ENV_NAME\s"; then
        echo -e "${YELLOW}Conda environment '$ENV_NAME' already exists.${RESET}"
        ask_yn "Do you want to delete and recreate it?"
        if [[ "$ANSWER" == "y" ]]; then
            conda remove -n "$ENV_NAME" --all -y
            echo -e "${GREEN}Creating Conda environment '$ENV_NAME' with Python $PYTHON_VER...${RESET}"
            conda create -n "$ENV_NAME" python="$PYTHON_VER" -y
        else
            echo -e "${YELLOW}Using existing environment.${RESET}"
        fi
    else
        echo -e "${GREEN}Creating Conda environment '$ENV_NAME' with Python $PYTHON_VER...${RESET}"
        conda create -n "$ENV_NAME" python="$PYTHON_VER" -y
    fi

    echo -e "${GREEN}Activating environment...${RESET}"
    # shellcheck disable=SC1091
    source "$(conda info --base)/etc/profile.d/conda.sh"
    conda activate "$ENV_NAME"
    check_environment_python

    echo -e "${CYAN}Upgrading pip...${RESET}"
    pip install --upgrade pip
fi

divider

# ============================================================================
# Step 4: Install PyTorch and Isaac Sim
# ============================================================================

echo -e "${CYAN}[Step 4] Installing Isaac Sim and PyTorch...${RESET}\n"

if [[ "$SELECTED_VERSION" == "v3.0.0" ]]; then
    # The release lockfile resolves Isaac Sim and PyTorch overrides together.
    echo -e "${CYAN}IsaacLab 3.0.0 dependencies will be installed together in Step 7.${RESET}"
else
    # Install IsaacSim first (per official docs order)
    echo -e "${GREEN}Installing IsaacSim for $SELECTED_VERSION...${RESET}"
    read -r -a ISAACSIM_PACKAGE_ARGS <<< "$ISAACSIM_PKGS"
    read -r -a ISAACSIM_FLAG_ARGS <<< "$ISAACSIM_EXTRA_FLAGS"
    if [ "$PKG_MANAGER" == "uv" ]; then
        uv pip install --upgrade "${ISAACSIM_PACKAGE_ARGS[@]}" --extra-index-url https://pypi.nvidia.com "${ISAACSIM_FLAG_ARGS[@]}"
    else
        pip install --upgrade "${ISAACSIM_PACKAGE_ARGS[@]}" --extra-index-url https://pypi.nvidia.com
    fi

    # Install PyTorch
    echo -e "\n${GREEN}Installing PyTorch $PYTORCH_VER ($CUDA_VER)...${RESET}"
    if [ -n "$TORCHVISION_VER" ]; then
        if [ "$PKG_MANAGER" == "uv" ]; then
            uv pip install -U "torch==$PYTORCH_VER" "$TORCHVISION_VER" --index-url "https://download.pytorch.org/whl/$CUDA_VER"
        else
            pip install -U "torch==$PYTORCH_VER" "$TORCHVISION_VER" --index-url "https://download.pytorch.org/whl/$CUDA_VER"
        fi
    else
        if [ "$PKG_MANAGER" == "uv" ]; then
            uv pip install -U "torch==$PYTORCH_VER" --index-url "https://download.pytorch.org/whl/$CUDA_VER"
        else
            pip install -U "torch==$PYTORCH_VER" --index-url "https://download.pytorch.org/whl/$CUDA_VER"
        fi
    fi
fi

divider

# ============================================================================
# Step 5: Verify Isaac Sim Installation
# ============================================================================

echo -e "${CYAN}[Step 5] Verifying Isaac Sim installation...${RESET}\n"

VERIFY_ISAACSIM="n"
if [[ "$INSTALL_BACKEND" == "newton" ]]; then
    echo -e "${YELLOW}Skipping Isaac Sim verification for the Newton backend.${RESET}"
else
    echo -e "${YELLOW}During the first run, you will be asked to accept the NVIDIA Omniverse EULA.${RESET}"

    ask_yn "Do you want to launch Isaac Sim graphical interface for verification?"
    if [[ "$ANSWER" == "y" ]]; then
        if [[ "$SELECTED_VERSION" == "v3.0.0" ]]; then
            VERIFY_ISAACSIM="y"
            echo -e "${YELLOW}Isaac Sim verification will run after Step 7.${RESET}"
        else
            echo -e "${GREEN}Launching Isaac Sim...${RESET}"
            echo -e "${YELLOW}Close the graphical interface to continue...${RESET}"
            isaacsim
        fi
    else
        echo -e "${YELLOW}Skipping graphical verification.${RESET}"
    fi
fi

divider

# ============================================================================
# Step 6: Clone Isaac Lab Repository
# ============================================================================

echo -e "${CYAN}[Step 6] Cloning Isaac Lab repository...${RESET}\n"

default_dir=$(pwd)
read -r -p "Enter the directory to clone Isaac Lab [default: $default_dir]: " clone_dir
clone_dir="${clone_dir:-$default_dir}"
# Match a literal tilde before expanding it, without evaluating user input.
# shellcheck disable=SC2088
case "$clone_dir" in
    '~') clone_dir="$HOME" ;;
    '~/'*) clone_dir="$HOME/${clone_dir:2}" ;;
esac

mkdir -p "$clone_dir"
cd "$clone_dir"
clone_dir=$(pwd)

PULL_LATEST="n"
if [ -d "$clone_dir/IsaacLab" ]; then
    echo -e "${YELLOW}IsaacLab already exists in $clone_dir.${RESET}"
    if [[ "$(git -C IsaacLab rev-parse --show-toplevel)" != "$clone_dir/IsaacLab" ]] || \
        [[ -n "$(git -C IsaacLab status --porcelain)" ]]; then
        echo -e "${RED}The existing repository has uncommitted changes or is not a separate Git repository. Please save your changes or choose another directory.${RESET}"
        exit 1
    fi
    ask_yn "Do you want to pull the latest changes?"
    cd IsaacLab
    if [[ "$ANSWER" == "y" ]]; then
        PULL_LATEST="y"
        echo -e "${GREEN}Fetching latest changes for $GIT_TAG...${RESET}"
        git fetch origin "$GIT_TAG"
    fi
else
    echo -e "${GREEN}Cloning Isaac Lab into $clone_dir...${RESET}"
    git clone https://github.com/isaac-sim/IsaacLab.git
    cd IsaacLab
fi

# An existing checkout must also match the version selected in Step 0.
echo -e "${GREEN}Checking out $GIT_TAG...${RESET}"
git checkout "$GIT_TAG"
if [[ "$PULL_LATEST" == "y" && "$GIT_TAG" != "v1.4.1" && "$GIT_TAG" != "v2.3.2" ]]; then
    echo -e "${GREEN}Pulling latest changes on branch $GIT_TAG...${RESET}"
    git pull --ff-only origin "$GIT_TAG"
fi

divider

# ============================================================================
# Step 7: Install Isaac Lab Dependencies
# ============================================================================

echo -e "${CYAN}[Step 7] Installing Isaac Lab dependencies...${RESET}\n"

if [[ "$SELECTED_VERSION" == "v3.0.0" ]]; then
    if [[ "$PKG_MANAGER" == "uv" ]]; then
        if [[ "$INSTALL_BACKEND" == "isaacsim" ]]; then
            uv sync --active --extra isaacsim
            uv run --active --extra isaacsim isaaclab --help
        else
            uv sync --active
            uv run --active isaaclab --help
        fi
    else
        INSTALL_TARGETS='newton,rl[rsl-rl],visualizer[newton]'
        if [[ "$INSTALL_BACKEND" == "isaacsim" ]]; then INSTALL_TARGETS+=',isaacsim'; fi
        ./isaaclab.sh --install "$INSTALL_TARGETS"
        ./isaaclab.sh --help
    fi
else
    ./isaaclab.sh --install
fi

divider

# ============================================================================
# Step 8: Verify Isaac Lab Installation
# ============================================================================

echo -e "${CYAN}[Step 8] Verifying Isaac Lab installation...${RESET}\n"

if [[ "$VERIFY_ISAACSIM" == "y" ]]; then
    echo -e "${GREEN}Launching Isaac Sim...${RESET}"
    echo -e "${YELLOW}Close the graphical interface to continue...${RESET}"
    isaacsim
fi

ask_yn "Do you want to verify Isaac Lab with a graphical interface?"
if [[ "$ANSWER" == "y" ]]; then
    echo -e "${GREEN}Launching verification script...${RESET}"
    echo -e "${YELLOW}Close the graphical interface to continue...${RESET}"
    if [ "$GIT_TAG" == "v1.4.1" ]; then
        python source/standalone/tutorials/00_sim/create_empty.py
    elif [[ "$SELECTED_VERSION" == "v3.0.0" && "$INSTALL_BACKEND" == "newton" ]]; then
        ./isaaclab.sh -p scripts/tutorials/00_sim/create_empty.py --viz newton
    elif [[ "$GIT_TAG" == "v2.3.2" ]]; then
        ./isaaclab.sh -p scripts/tutorials/00_sim/create_empty.py
    else
        ./isaaclab.sh -p scripts/tutorials/00_sim/create_empty.py --viz kit
    fi
else
    echo -e "${YELLOW}Skipping graphical verification.${RESET}"
fi

divider

# ============================================================================
# Completion
# ============================================================================

if [[ "$INSTALL_BACKEND" == "newton" ]]; then
    echo -e "${GREEN}${BOLD}Isaac Lab installation completed successfully (Newton backend)!${RESET}\n"
else
    echo -e "${GREEN}${BOLD}Isaac Sim and Isaac Lab installation completed successfully!${RESET}\n"
fi
echo -e "${CYAN}To use IsaacLab, activate your environment:${RESET}\n"

if [ "$PKG_MANAGER" == "uv" ]; then
    echo -e "  ${YELLOW}source ~/.venvs/$ENV_NAME/bin/activate${RESET}"
    echo -e "\n${CYAN}Tip: Add this alias to your ~/.bashrc for convenience:${RESET}"
    echo -e "  ${YELLOW}alias activate-isaaclab='source ~/.venvs/$ENV_NAME/bin/activate'${RESET}"
else
    echo -e "  ${YELLOW}conda activate $ENV_NAME${RESET}"
fi

divider
print_author_info
divider
