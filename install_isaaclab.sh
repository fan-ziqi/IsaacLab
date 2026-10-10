#!/usr/bin/env bash
# Copyright (c) 2022-2026, The Isaac Lab Project Developers (https://github.com/isaac-sim/IsaacLab/blob/main/CONTRIBUTORS.md).
# All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause

# Bootstrap uv and run the Python installer, preferring the copy next to this file.
set -euo pipefail

installer_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if ! command -v uv >/dev/null 2>&1; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="${HOME}/.local/bin:${PATH}"
fi

if [[ -f "${installer_dir}/install.py" ]]; then
    installer_path="${installer_dir}/install.py"
else
    installer_tmp="$(mktemp -d)"
    trap 'rm -rf -- "$installer_tmp"' EXIT
    installer_path="${installer_tmp}/install.py"
    curl -fLsS https://raw.githubusercontent.com/fan-ziqi/IsaacLab/main/install.py -o "$installer_path"
fi
uv run --no-project --no-config --script "$installer_path" "$@"
