#!/usr/bin/env bash
# Copyright (c) 2026, The Isaac Lab Project Developers (https://github.com/isaac-sim/IsaacLab/blob/main/CONTRIBUTORS.md).
# All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause

set -euo pipefail

# Append reviewed snapshots to the permanent interactive-demos release; retain earlier assets.
readonly archive_commit="897b81dd82115d319fbfc56c02f33f936f22ab72"
readonly archive_url="https://github.com/isaac-sim/IsaacLab/releases/download/interactive-demos/isaaclab-browser-demos-${archive_commit}.tar.gz"
readonly archive_sha256="08f27711b72fa8b1fffd8fb7f433fbd34775e2e526f0bc94da7f487458b5100a"
readonly build_dir="${DOCS_BUILD_DIR:-docs/_build}"

archive=$(mktemp)
trap 'rm -f "$archive"' EXIT

curl --fail --silent --show-error --location --retry 3 --connect-timeout 15 --max-time 180 \
  "$archive_url" --output "$archive"
printf '%s  %s\n' "$archive_sha256" "$archive" | sha256sum --check

mkdir -p "$build_dir/demos"
tar --extract --gzip --file "$archive" --directory "$build_dir/demos" --no-same-owner \
  --strip-components=2 "IsaacLab-${archive_commit}/site/"

# Resolve links per version so local artifacts and nested release branches use the same files.
DOCS_BUILD_DIR="$build_dir" python3 - <<'PY'
import os
from pathlib import Path

build = Path(os.environ["DOCS_BUILD_DIR"])
pages = list(build.glob("**/source/isaaclab/interactive_demos.html"))
pages.extend(build.glob("**/source/setup/interactive_demos.html"))
for page in pages:
    relative = Path(os.path.relpath(build / "demos", page.parent)).as_posix()
    content = page.read_text()
    page.write_text(content.replace('href="../../../demos/', f'href="{relative}/'))
PY

if [[ -d "$build_dir/current" ]]; then
  cat > "$build_dir/PREVIEW.txt" <<'TXT'
Extract the complete docs-html artifact, then run this command in its root directory:

    python -m http.server 8000

Documentation: http://localhost:8000/current/index.html
Interactive demos: http://localhost:8000/demos/interactive/

Use HTTP to preview the demos; opening the HTML files directly does not allow
the browser to load their WebAssembly modules and data through fetch().
TXT
fi

if [[ -f "$build_dir/index.html" ]]; then
  cat > "$build_dir/PREVIEW.txt" <<'TXT'
Extract the complete HTML artifact, then run this command in its root directory:

    python -m http.server 8000

Documentation: http://localhost:8000/index.html
Interactive demos: http://localhost:8000/demos/interactive/

Use HTTP so the browser can load the WebAssembly modules and data.
TXT
fi
