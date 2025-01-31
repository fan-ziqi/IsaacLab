# Copyright (c) 2022-2025, The Isaac Lab Project Developers.
# All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause

import os
import re


def replace_in_file(file_path, search_word_list, replace_word_list):
    """Replace occurrences of search_word with replace_word in a file."""
    if (
        file_path.endswith(".py")
        or file_path.endswith(".rst")
        or file_path.endswith(".md")
        or file_path.endswith(".toml")
    ):
        print(file_path)
        with open(file_path, encoding="utf-8") as file:
            file_content = file.read()

        # Use regular expression to match whole word occurrences
        for search_word, replace_word in zip(search_word_list, replace_word_list):
            file_content = re.sub(re.escape(search_word), replace_word, file_content)

        with open(file_path, "w", encoding="utf-8") as file:
            file.write(file_content)


def replace_in_directory(root_dir, search_word_list, replace_word_list):
    """Recursively replace occurrences of search_word with replace_word in all files under root_dir."""
    for root, dirs, files in os.walk(root_dir):
        for file_name in files:
            file_path = os.path.join(root, file_name)
            replace_in_file(file_path, search_word_list, replace_word_list)
        for subdir in dirs:
            if "logs" in subdir:
                continue
            replace_in_directory(os.path.join(root, subdir), search_word_list, replace_word_list)


mapping = {
    "omni.isaac.lab_tasks.utils.wrappers": "isaaclab_rl",
    "omni.isaac.lab": "isaaclab",
    "omni/isaac/lab": "isaaclab",
    "omni\\isaac\\lab": "isaaclab",
    "source/extensions": "source",
    "source\\extensions": "source",
    "source/standalone": "scripts",
    "source\\standalone": "scripts",
    "source/apps": "apps",
    "source\\apps": "apps",
}

# Example usage:
root_directory = "source"
search_word_list = list(mapping.keys())
replace_word_list = list(mapping.values())
replace_in_directory(root_directory, search_word_list, replace_word_list)

root_directory = "docs"
replace_in_directory(root_directory, search_word_list, replace_word_list)
