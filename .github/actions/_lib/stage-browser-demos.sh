#!/usr/bin/env bash
# Copyright (c) 2026, The Isaac Lab Project Developers (https://github.com/isaac-sim/IsaacLab/blob/main/CONTRIBUTORS.md).
# All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause

set -euo pipefail

# Keep the archive and checksum pinned together; retain published version directories in each release.
readonly archive_url="https://github.com/isaac-sim/IsaacLab/releases/download/browser-demos-v3/isaaclab-browser-demos-v3.tar.gz"
readonly archive_sha256="a860b7e59793d553545b76abf2b09d15ff20685972ec803c6c07163e6678f64a"
readonly build_dir="${DOCS_BUILD_DIR:-docs/_build}"

archive=$(mktemp)
trap 'rm -f "$archive"' EXIT

curl --fail --silent --show-error --location --retry 3 --connect-timeout 15 --max-time 180 \
  "$archive_url" --output "$archive"
printf '%s  %s\n' "$archive_sha256" "$archive" | sha256sum --check

mkdir -p "$build_dir/demos"
tar --extract --gzip --file "$archive" --directory "$build_dir/demos" --no-same-owner

# Resolve links per version so local artifacts and nested release branches use the same files.
DOCS_BUILD_DIR="$build_dir" python3 - <<'PY'
import os
from pathlib import Path

build = Path(os.environ["DOCS_BUILD_DIR"])
for page in build.glob("**/source/setup/interactive_demos.html"):
    relative = Path(os.path.relpath(build / "demos", page.parent)).as_posix()
    content = page.read_text()
    page.write_text(content.replace('href="../../../demos/', f'href="{relative}/'))
PY

if [[ -d "$build_dir/current" ]]; then
  cat > "$build_dir/PREVIEW.txt" <<'TXT'
Extract the complete docs-html artifact, then run this command in its root directory:

    python -m http.server 8000

Documentation: http://localhost:8000/current/index.html
Interactive demos: http://localhost:8000/demos/v3/

Use HTTP to preview the demos; opening the HTML files directly does not allow
the browser to load their WebAssembly modules and data through fetch().
TXT
fi

if [[ -f "$build_dir/index.html" ]]; then
  cat > "$build_dir/PREVIEW.txt" <<'TXT'
Extract the complete HTML artifact, then run this command in its root directory:

    python -m http.server 8000

Documentation: http://localhost:8000/index.html
Interactive demos: http://localhost:8000/demos/v3/

Use HTTP so the browser can load the WebAssembly modules and data.
TXT
fi
