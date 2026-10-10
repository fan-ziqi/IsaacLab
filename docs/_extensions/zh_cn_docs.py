# Copyright (c) 2022-2026, The Isaac Lab Project Developers (https://github.com/isaac-sim/IsaacLab/blob/main/CONTRIBUTORS.md).
# All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause

"""Chinese-site presentation fixes that preserve upstream English sources."""

from __future__ import annotations

import html
import json
import posixpath
import re
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlparse

from docutils import nodes

_UI_TRANSLATIONS = json.loads(Path(__file__).with_name("zh_cn_ui.json").read_text(encoding="utf-8"))
_UI_ATTRIBUTES = {"title", "alt", "placeholder", "aria-label", "data-demo-name", "data-demo-description"}


class _LocalizedHTML(HTMLParser):
    """Translate visible raw-HTML prose while retaining URLs and machine attributes."""

    def __init__(self):
        super().__init__(convert_charrefs=False)
        self.output = []
        self.literal_depth = 0

    def handle_starttag(self, tag, attrs):
        original = self.get_starttag_text()
        for key, value in attrs:
            if key in _UI_ATTRIBUTES and value in _UI_TRANSLATIONS:
                replacement = html.escape(_UI_TRANSLATIONS[value], quote=True)
                original = re.sub(
                    rf"(\b{re.escape(key)}\s*=\s*)([\"'])(.*?)\2",
                    lambda match: match[1] + match[2] + replacement + match[2],
                    original,
                    flags=re.DOTALL,
                )
        self.output.append(original)
        if tag in {"script", "style", "code", "pre", "kbd"}:
            self.literal_depth += 1

    def handle_startendtag(self, tag, attrs):
        self.handle_starttag(tag, attrs)

    def handle_endtag(self, tag):
        self.output.append(f"</{tag}>")
        if tag in {"script", "style", "code", "pre", "kbd"}:
            self.literal_depth -= 1

    def handle_data(self, data):
        normalized = " ".join(data.split())
        if not self.literal_depth and normalized in _UI_TRANSLATIONS:
            # Preserve whitespace around inline elements such as keyboard shortcuts.
            leading = re.match(r"\s*", data)[0]
            trailing = re.search(r"\s*$", data)[0]
            data = leading + html.escape(_UI_TRANSLATIONS[normalized]) + trailing
        self.output.append(data)

    def handle_entityref(self, name):
        self.output.append(f"&{name};")

    def handle_charref(self, name):
        self.output.append(f"&#{name};")

    def handle_comment(self, data):
        self.output.append(f"<!--{data}-->")

    def handle_decl(self, decl):
        self.output.append(f"<!{decl}>")


def localize_raw_html(app, doctree, docname):
    if app.builder.format != "html" or app.config.language != "zh_CN":
        return
    for node in doctree.findall(nodes.raw):
        if "html" in node.get("format", ""):
            parser = _LocalizedHTML()
            parser.feed(node.astext())
            parser.close()
            node.clear()
            node += nodes.Text("".join(parser.output))


def add_ui_translations(app):
    if app.builder.format == "html" and app.config.language == "zh_CN":
        app.add_js_file(
            None,
            body="window.isaacLabDocsTranslations = " + json.dumps(_UI_TRANSLATIONS, ensure_ascii=False) + ";",
            priority=100,
        )
        app.add_js_file("zh-cn-ui.js", priority=110)
        app.add_js_file("media-status.js", priority=120)


_BADGES = {
    "IsaacSim-6.1.0-silver.svg": "isaacsim-6.1.0.svg",
    "python-3.12-blue.svg": "python-3.12.svg",
    "Ubuntu-24.04-orange.svg": "ubuntu-24.04.svg",
    "Windows-11-blue.svg": "windows-11.svg",
    "platform-windows--64-orange.svg": "windows-11.svg",
    "platform-linux--64-orange.svg": "ubuntu-24.04.svg",
}


def localize_badges(app, doctree, docname):
    """Use bundled version badges so the Chinese HTML also works offline."""
    if app.builder.format != "html" or app.config.language != "zh_CN":
        return
    for node in doctree.findall(nodes.image):
        parsed = urlparse(node.get("uri", ""))
        if parsed.hostname != "img.shields.io":
            continue
        badge = _BADGES.get(unquote(parsed.path).removeprefix("/badge/"))
        if badge is not None:
            node["uri"] = posixpath.relpath(f"_static/badges/{badge}", posixpath.dirname(docname) or ".")


def link_repository_files(app, doctree, docname):
    """Resolve source-tree links that would otherwise point outside built HTML."""
    if app.builder.format != "html":
        return
    source_root = Path(app.srcdir).resolve()
    repository = source_root.parent
    for node in doctree.findall(nodes.reference):
        uri = node.get("refuri", "")
        parsed = urlparse(uri)
        if parsed.scheme or parsed.netloc or not parsed.path.startswith("../"):
            continue
        target = (source_root / docname).parent / unquote(parsed.path)
        target = target.resolve()
        if target.is_file() and target.is_relative_to(repository) and not target.is_relative_to(source_root):
            path = target.relative_to(repository).as_posix()
            node["refuri"] = (
                f"https://github.com/isaac-sim/IsaacLab/blob/{app.config.isaaclab_latest_branch}/{path}"
                + (f"#{parsed.fragment}" if parsed.fragment else "")
            )


def setup(app):
    app.connect("builder-inited", add_ui_translations)
    app.connect("doctree-resolved", localize_badges)
    app.connect("doctree-resolved", localize_raw_html)
    app.connect("doctree-resolved", link_repository_files)
    return {"version": "1.2", "parallel_read_safe": True, "parallel_write_safe": True}
