#!/usr/bin/env python3
# Copyright (c) 2022-2026, The Isaac Lab Project Developers (https://github.com/isaac-sim/IsaacLab/blob/main/CONTRIBUTORS.md).
# All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause

# Copyright (c) 2024, Ziqi Fan
# All rights reserved.
# 该脚本完整实现了原始Bash脚本的所有功能，包含完整的错误处理和用户交互
#
# /// script
# requires-python = ">=3.10"
# dependencies = ["InquirerPy>=0.3.4,<0.4", "rich>=13"]
# ///

"""Install a selected Isaac Lab release in an isolated Linux environment."""

import argparse
import json
import os
import platform
import re
import shlex
import shutil
import subprocess
import sys
from pathlib import Path

from InquirerPy import inquirer
from rich.console import Console
from rich.panel import Panel

REPOSITORY_URL = "https://github.com/isaac-sim/IsaacLab.git"
RELEASES = {
    "3.0.0": {"revision": "release/3.0.0", "python": "3.12", "glibc": "2.35"},
    "2.3.2": {
        "revision": "v2.3.2",
        "python": "3.11",
        "glibc": "2.35",
        "isaacsim": "5.1.0",
        "torch": "2.7.0",
        "torchvision": "0.22.0",
        "cuda": "cu128",
    },
    "1.4.1": {
        "revision": "v1.4.1",
        "python": "3.10",
        "glibc": "2.34",
        "isaacsim": "4.2.0.2",
        "torch": "2.4.0",
        "torchvision": "0.19.0",
        "cuda": "cu118",
    },
}


class IsaacInstaller:
    def __init__(self, args: argparse.Namespace):
        self.console = Console()
        self.version = args.version
        self.manager = args.manager
        self.backend = args.backend
        self.repo_path = args.directory
        self.env_name = args.env_name
        self.dry_run = args.dry_run
        self.command_env = os.environ.copy()
        # Do not let the environment running this installer select the install target.
        for key in (
            "VIRTUAL_ENV",
            "CONDA_PREFIX",
            "CONDA_DEFAULT_ENV",
            "PYTHONPATH",
            "UV_PROJECT_ENVIRONMENT",
            "UV_PYTHON",
        ):
            self.command_env.pop(key, None)

    def run_cmd(self, cmd: list[str], *, capture: bool = False, cwd: Path | None = None):
        """Run an argument vector, or print it without executing in dry-run mode."""
        self.console.print(f"$ {shlex.join(cmd)}", markup=False)
        if self.dry_run:
            return subprocess.CompletedProcess(cmd, 0, stdout="", stderr="")
        return subprocess.run(cmd, check=True, text=True, capture_output=capture, cwd=cwd, env=self.command_env)

    def select_options(self):
        if self.version is None:
            self.version = inquirer.select(message="选择 Isaac Lab 版本：", choices=list(RELEASES)).execute()
        if self.manager is None:
            self.manager = inquirer.select(message="选择包管理器：", choices=["uv", "conda"]).execute()
        if self.backend is None:
            self.backend = (
                inquirer.select(
                    message="选择安装内容：",
                    choices=[
                        {"name": "完整 Isaac Sim 工作流", "value": "isaacsim"},
                        {"name": "Newton（不安装 Isaac Sim）", "value": "newton"},
                    ],
                ).execute()
                if self.version == "3.0.0"
                else "isaacsim"
            )
        if self.version != "3.0.0" and self.backend != "isaacsim":
            raise ValueError("Newton 安装选项仅支持 Isaac Lab 3.0.0。")
        if self.repo_path is None:
            self.repo_path = Path(
                inquirer.text(message="Isaac Lab 安装目录：", default=str(Path.cwd() / "IsaacLab")).execute()
            )
        self.repo_path = self.repo_path.expanduser().resolve()
        if not re.fullmatch(r"[A-Za-z0-9_][A-Za-z0-9_-]*", self.env_name):
            raise ValueError("Conda 环境名只能包含字母、数字、下划线和连字符，不能以连字符开头。")
        self.release = RELEASES[self.version]
        self.console.print(
            Panel(
                f"Isaac Lab {self.version} · {self.release['revision']}\n"
                f"Python {self.release['python']} · {self.manager} · {self.backend}\n{self.repo_path}",
                title="一键安装（非官方）" if not self.dry_run else "安装预览（不执行命令）",
            )
        )

    def check_system(self):
        if self.dry_run:
            self.console.print("实际安装前将检查 Linux、GLIBC、NVIDIA 驱动和包管理器。")
            return
        if platform.system() != "Linux" or platform.machine() not in ("x86_64", "aarch64"):
            raise RuntimeError("此脚本支持 Linux x86_64 和 aarch64；其他平台请使用官方安装指南。")
        if self.version != "3.0.0" and platform.machine() != "x86_64":
            raise RuntimeError("旧版本安装组合仅支持 Linux x86_64。")
        libc, version = platform.libc_ver()
        if libc != "glibc" or tuple(map(int, version.split("."))) < tuple(map(int, self.release["glibc"].split("."))):
            raise RuntimeError(
                f"需要 GLIBC >= {self.release['glibc']}，当前为 {libc} {version}。"
                "请使用受支持的系统；脚本不会修改系统软件源或升级 GLIBC。"
            )
        for command in ("git", "nvidia-smi", self.manager):
            if not shutil.which(command):
                raise RuntimeError(f"未找到 {command}，请先安装并将其加入 PATH。")
        result = self.run_cmd(["nvidia-smi", "--query-gpu=driver_version", "--format=csv,noheader"], capture=True)
        drivers = result.stdout.splitlines()
        if not drivers:
            raise RuntimeError("未检测到 NVIDIA GPU。")
        if self.version == "3.0.0":
            if any(tuple(map(int, driver.strip().split("."))) < (580, 65, 6) for driver in drivers):
                raise RuntimeError("CUDA 13.0 需要 NVIDIA 驱动 >= 580.65.06；建议使用官方指南推荐的生产驱动。")
        self.console.print("系统检查通过。预编译 PyTorch 包包含 CUDA 运行时，无需预先安装 nvcc。")

    def clone_isaaclab(self):
        revision = self.release["revision"]
        if self.repo_path.exists():
            root = self.run_cmd(["git", "rev-parse", "--show-toplevel"], capture=True, cwd=self.repo_path)
            if not self.dry_run and Path(root.stdout.strip()).resolve() != self.repo_path:
                raise RuntimeError("安装目录不是独立的 Git 仓库，请选择一个新目录。")
            status = self.run_cmd(["git", "status", "--porcelain"], capture=True, cwd=self.repo_path)
            if not self.dry_run and status.stdout.strip():
                raise RuntimeError("安装目录有未提交的修改，已停止安装。请先保存修改，或选择一个新目录。")
            self.run_cmd(["git", "fetch", "--depth", "1", REPOSITORY_URL, revision], cwd=self.repo_path)
            self.run_cmd(["git", "checkout", "--detach", "FETCH_HEAD"], cwd=self.repo_path)
        else:
            if not self.dry_run:
                self.repo_path.parent.mkdir(parents=True, exist_ok=True)
            self.run_cmd(["git", "clone", "--branch", revision, "--depth", "1", REPOSITORY_URL, str(self.repo_path)])

    def run_in_environment(self, cmd: list[str], *, capture: bool = False):
        if self.manager == "conda":
            cmd = ["conda", "run", "--no-capture-output", "-n", self.env_name, *cmd]
        return self.run_cmd(cmd, capture=capture, cwd=self.repo_path)

    def create_environment(self):
        python_version = self.release["python"]
        if self.manager == "uv" and self.version == "3.0.0":
            venv = self.repo_path / ".venv"
            if not venv.exists():
                return  # uv sync creates a fresh project environment.
            python = str(venv / "bin" / "python")
            if not Path(python).exists() and not self.dry_run:
                raise RuntimeError("已有 .venv 不含可用的 Python，请选择新的安装目录。")
        elif self.manager == "conda":
            result = self.run_cmd(["conda", "env", "list", "--json"], capture=True)
            exists = not self.dry_run and any(Path(p).name == self.env_name for p in json.loads(result.stdout)["envs"])
            if not exists:
                self.run_cmd(["conda", "create", "-n", self.env_name, f"python={python_version}", "pip", "-y"])
            python = "python"
        else:
            python = str(self.repo_path / "env_isaaclab" / "bin" / "python")
            if not Path(python).exists():
                self.run_cmd(["uv", "venv", "--python", python_version, "--seed", "env_isaaclab"], cwd=self.repo_path)
        probe = self.run_in_environment(
            [python, "-c", "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"], capture=True
        )
        if not self.dry_run and probe.stdout.strip() != python_version:
            raise RuntimeError(f"已有环境的 Python 版本不是 {python_version}，请使用新环境名或新安装目录。")

    def install_dependencies(self):
        if self.version == "3.0.0":
            if self.manager == "uv":
                cmd = ["uv", "sync", "--python", "3.12"]
                if self.backend == "isaacsim":
                    cmd.extend(["--extra", "isaacsim"])
                self.run_cmd(cmd, cwd=self.repo_path)
            else:
                targets = "newton,rl[rsl-rl],visualizer[newton]"
                if self.backend == "isaacsim":
                    targets += ",isaacsim"
                # The upstream installer reads all version pins from its pyproject.toml.
                self.run_in_environment(["bash", "./isaaclab.sh", "--install", targets])
            return
        python = "python" if self.manager == "conda" else str(self.repo_path / "env_isaaclab/bin/python")
        pip = (
            [python, "-m", "pip", "install"]
            if self.manager == "conda"
            else ["uv", "pip", "install", "--python", python]
        )
        self.run_in_environment(
            [
                *pip,
                f"torch=={self.release['torch']}",
                f"torchvision=={self.release['torchvision']}",
                "--index-url",
                f"https://download.pytorch.org/whl/{self.release['cuda']}",
            ]
        )
        sim_version = self.release["isaacsim"]
        sim_packages = (
            [
                f"{name}=={sim_version}"
                for name in (
                    "isaacsim",
                    "isaacsim-extscache-physics",
                    "isaacsim-extscache-kit",
                    "isaacsim-extscache-kit-sdk",
                )
            ]
            if self.version == "1.4.1"
            else [f"isaacsim[all,extscache]=={sim_version}"]
        )
        self.run_in_environment([*pip, *sim_packages, "--extra-index-url", "https://pypi.nvidia.com"])
        if self.manager == "uv":
            self.command_env["VIRTUAL_ENV"] = str(self.repo_path / "env_isaaclab")
        self.run_in_environment(["bash", "./isaaclab.sh", "--install", "rsl_rl"])

    def verify_installation(self):
        if self.version == "3.0.0":
            if self.manager == "uv":
                cmd = ["uv", "run"]
                if self.backend == "isaacsim":
                    cmd.extend(["--extra", "isaacsim"])
                cmd.extend(["isaaclab", "--help"])
            else:
                cmd = ["isaaclab", "--help"]
        else:
            script = "scripts/tutorials/00_sim/create_empty.py"
            if not self.dry_run and not (self.repo_path / script).exists():
                script = "source/standalone/tutorials/00_sim/create_empty.py"
            cmd = ["bash", "./isaaclab.sh", "--python", script, "--help"]
        self.run_in_environment(cmd)

    def run_installation(self):
        self.select_options()
        self.check_system()
        self.clone_isaaclab()
        self.create_environment()
        self.install_dependencies()
        self.verify_installation()
        self.console.print("安装预览结束，未执行命令。" if self.dry_run else "安装和命令行入口检查完成。")
        self.console.print(f"项目目录：{self.repo_path}", markup=False)
        if self.manager == "conda":
            self.console.print(f"使用环境：conda activate {self.env_name}", markup=False)
        elif self.version == "3.0.0":
            extra = " --extra isaacsim" if self.backend == "isaacsim" else ""
            self.console.print(f"后续在项目目录中使用：uv run{extra} isaaclab ...", markup=False)
        else:
            self.console.print(
                f"使用环境：source {shlex.quote(str(self.repo_path / 'env_isaaclab/bin/activate'))}", markup=False
            )
        self.console.print("首次启动 Isaac Sim 时，请阅读并自行确认 NVIDIA 的许可协议。")


def main() -> int:
    parser = argparse.ArgumentParser(description="Isaac Lab 一键安装脚本（Linux，非官方）")
    parser.add_argument("--version", choices=RELEASES, help="Isaac Lab 版本；3.0.0 使用 release/3.0.0 分支")
    parser.add_argument("--manager", choices=("uv", "conda"), help="安装环境的包管理器")
    parser.add_argument("--backend", choices=("isaacsim", "newton"), help="3.0.0 可选完整 Isaac Sim 或 Newton 安装")
    parser.add_argument("--directory", type=Path, help="Isaac Lab 仓库的安装目录")
    parser.add_argument("--env-name", default="isaaclab", help="Conda 环境名，默认 isaaclab")
    parser.add_argument("--dry-run", action="store_true", help="仅显示安装命令，不执行或修改安装目录")
    args = parser.parse_args()
    try:
        IsaacInstaller(args).run_installation()
    except (OSError, ValueError, RuntimeError, subprocess.CalledProcessError) as exc:
        Console().print(f"安装停止：{exc}", style="bold red", markup=False)
        return 1
    except (KeyboardInterrupt, EOFError):
        return 130
    return 0


if __name__ == "__main__":
    sys.exit(main())
