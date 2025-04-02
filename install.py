#!/usr/bin/env python3
# Copyright (c) 2024, Ziqi Fan
# All rights reserved.
# 该脚本完整实现了原始Bash脚本的所有功能，包含完整的错误处理和用户交互

import os
import re
import sys
import subprocess
from enum import Enum
from pathlib import Path
from functools import partial
from typing import Callable, List, Dict, Tuple

from InquirerPy import inquirer, separator
from InquirerPy.validator import PathValidator
from rich.console import Console
from rich.panel import Panel
from rich.style import Style
from rich.table import Table


class Color(Enum):
    RED = "red"
    GREEN = "green"
    YELLOW = "yellow"
    BLUE = "blue"
    CYAN = "cyan"
    RESET = "reset"


class IsaacInstaller:
    def __init__(self):
        self.console = Console()
        self.conda_env = "isaaclab"
        self.isaac_version = "2"
        self.cuda_version = ""
        self.glibc_version = ""
        self.project_path = Path.cwd()
        self.pytorch_index_url = ""
        self.required_glibc = "2.34"

        # 配置颜色样式
        self.styles = {
            "error": Style(color=Color.RED.value, bold=True),
            "warning": Style(color=Color.YELLOW.value),
            "success": Style(color=Color.GREEN.value),
            "info": Style(color=Color.CYAN.value),
            "prompt": Style(color="cyan", bold=True),
        }

    def run_cmd(
        self,
        cmd: str,
        error_msg: str = "",
        capture: bool = False,
        check: bool = True,
    ) -> subprocess.CompletedProcess:
        """执行系统命令并进行错误处理"""
        try:
            result = subprocess.run(
                cmd,
                shell=True,
                check=check,
                executable="/bin/bash",
                capture_output=capture,
                text=True,  # Ensure the output is captured as text
            )
            return result
        except subprocess.CalledProcessError as e:
            self.console.print(
                f"[{Color.RED.value}]Error executing command: {e.cmd}", style="bold"
            )
            self.console.print(f"Error message: {e.stderr}", style=self.styles["error"])
            if error_msg:
                self.console.print(error_msg, style=self.styles["error"])
            sys.exit(1)


    def prompt_confirm(self, message: str, default: bool = True) -> bool:
        """确认对话框"""
        return inquirer.confirm(
            message=message,
            default=default,
            transformer=lambda x: "Yes" if x else "No",
            # style=self.styles["prompt"],
        ).execute()

    def prompt_select(self, message: str, choices: List[str]) -> str:
        """选择对话框"""
        return inquirer.select(
            message=message,
            choices=choices,
            # style=self.styles["prompt"],
        ).execute()

    # 安装步骤
    def print_header(self):
        """打印头部信息"""
        self.console.print(
            Panel.fit(
                "One-click Installation Script for IsaacSim and IsaacLab (pip only)\n"
                "Version: v2.0.0\n"
                "Author: Ziqi Fan\n"
                "Email: fanziqi614@gmail.com\n"
                "GitHub: https://github.com/fan-ziqi\n"
                "CN Document: https://docs.robotsfan.com/isaaclab\n"
                "Feedback: https://github.com/fan-ziqi/IsaacLab/issues",
                title="Installation Information",
                border_style=Color.CYAN.value,
            )
        )

    def check_nvidia(self):
        """步骤1：检查NVIDIA驱动"""
        self.console.print(
            f"[bold {Color.CYAN.value}][Step 1] Checking NVIDIA GPU and drivers...[/]"
        )

        try:
            result = self.run_cmd("nvidia-smi", capture=True)
            table = Table(show_header=False, box=None)
            table.add_column("Info", style=Color.CYAN.value)
            table.add_column("Value", style=Color.GREEN.value)

            # 在输出中查找包含驱动版本和CUDA版本的行
            for line in result.stdout.split("\n"):
                if "Driver Version" in line:
                    driver_ver = line.split("Driver Version:")[-1].strip().split()[0]
                    table.add_row("Driver Version", driver_ver)
                if "CUDA Version" in line:
                    cuda_ver = line.split("CUDA Version:")[-1].strip().split()[0]
                    table.add_row("Minimal CUDA Version", cuda_ver)

            self.console.print(table)
        except FileNotFoundError:
            self.console.print(
                "[bold red]NVIDIA drivers not found![/]\n"
                "Please install NVIDIA drivers first.\n"
                "Download: https://www.nvidia.com/Download/index.aspx",
                style=self.styles["error"],
            )
            sys.exit(1)

    def check_cuda(self):
        """步骤2：检查CUDA安装"""
        self.console.print(
            f"[bold {Color.CYAN.value}][Step 2] Checking CUDA installation...[/]"
        )

        result = self.run_cmd("nvcc --version", capture=True)
        cuda_full_ver = re.search(r"release (\d+\.\d+)", result.stdout).group(1)
        self.cuda_version = cuda_full_ver.split(".")[0]

        table = Table(show_header=False, box=None)
        table.add_column(style=Color.CYAN.value)
        table.add_column(style=Color.GREEN.value)
        table.add_row("Full Version", cuda_full_ver)
        self.console.print(table)

        if self.cuda_version not in ["11", "12"]:
            self.console.print(
                f"[{Color.RED.value}]Unsupported CUDA version: {cuda_full_ver}[/]",
                style=self.styles["error"],
            )
            sys.exit(1)

    def check_glibc(self):
        """步骤4：检查GLIBC版本"""
        self.console.print(
            f"[bold {Color.CYAN.value}][Step 4] Checking GLIBC version...[/]"
        )

        result = self.run_cmd("ldd --version | head -n1", capture=True)
        self.glibc_version = re.search(r"(\d+\.\d+)", result.stdout).group(1)

        table = Table(show_header=False, box=None)
        table.add_column(style=Color.CYAN.value)
        table.add_column(style=Color.GREEN.value)
        table.add_row("Current Version", self.glibc_version)
        table.add_row("Minimal Required Version", self.required_glibc)
        self.console.print(table)

        if self.glibc_version < self.required_glibc:
            self.console.print(
                Panel.fit(
                    "WARNING: Upgrading GLIBC may cause system instability!\n"
                    "Only proceed if you understand the risks.",
                    title="! RISK WARNING !",
                    style=Style(color="red", bold=True),
                    border_style="red",
                )
            )

            if not self.prompt_confirm(
                "Proceed with GLIBC upgrade?", default=False
            ):
                self.console.print(
                    "Installation aborted by user.", style=self.styles["warning"]
                )
                sys.exit(1)

            self._upgrade_glibc()

    def _upgrade_glibc(self):
        """执行GLIBC升级"""
        self.console.print("Starting GLIBC upgrade...", style=self.styles["info"])

        try:
            # 备份源列表
            self.run_cmd(
                "sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak",
                "Failed to backup sources.list",
            )

            # 添加临时源
            with open("/etc/apt/sources.list", "a") as f:
                f.write("\ndeb http://th.archive.ubuntu.com/ubuntu jammy main\n")

            # 更新并安装
            self.run_cmd("sudo apt update", "Failed to update package list")
            self.run_cmd("sudo apt install -y libc6", "Failed to install libc6")

            # 验证版本
            result = self.run_cmd("ldd --version | head -n1", capture=True)
            new_version = re.search(r"(\d+\.\d+)", result.stdout).group(1)
            if new_version < self.required_glibc:
                raise Exception("GLIBC upgrade failed")

        except Exception as e:
            self.console.print(
                f"[{Color.RED.value}]GLIBC upgrade failed: {str(e)}[/]",
                style=self.styles["error"],
            )
            # 恢复备份
            self.run_cmd(
                "sudo mv /etc/apt/sources.list.bak /etc/apt/sources.list",
                "Failed to restore sources.list",
            )
            sys.exit(1)
        finally:
            self.run_cmd("sudo apt update")

    def manage_conda_env(self):
        """步骤5：管理Conda环境"""
        self.console.print(
            f"[bold {Color.CYAN.value}][Step 5] Managing Conda environment...[/]"
        )

        # 获取环境名称
        self.conda_env = inquirer.text(
            message="Enter Conda environment name:",
            default=self.conda_env,
            validate=lambda x: re.match(r"^\w+$", x),
            invalid_message="Invalid environment name (letters, numbers, underscores only)",
        ).execute()

        # 检查环境是否存在
        result = self.run_cmd(
            f"conda env list | grep '^{self.conda_env}\s'",
            check=False,
            capture=True,
        )

        if result.returncode == 0:
            choice = self.prompt_select(
                f"Environment '{self.conda_env}' exists:",
                ["Delete and recreate", "Use existing", "Exit"],
            )

            if choice == "Delete and recreate":
                self.run_cmd(f"conda remove -n {self.conda_env} --all -y")
                self.run_cmd(f"conda create -n {self.conda_env} python=3.10 -y")
            elif choice == "Exit":
                return  # 不退出 shell，避免终止整个进程
        else:
            self.run_cmd(f"conda create -n {self.conda_env} python=3.10 -y")

        # **关键1：获取 Conda 基路径**
        conda_base = subprocess.check_output("conda info --base", shell=True).decode().strip()
        if not conda_base:
            self.console.print("[bold red]Failed to detect Conda base path. Make sure Conda is installed and available.[/]")
            return

        # **关键2：手动 source conda.sh 并激活环境**
        activate_cmd = f'source "{conda_base}/etc/profile.d/conda.sh" && conda activate {self.conda_env} && echo "Activated {self.conda_env}"'

        # **关键3：在当前进程中执行，不新开 shell**
        result = subprocess.run(activate_cmd, shell=True, executable="/bin/bash", capture_output=True, text=True)

        if "Activated" in result.stdout:
            self.console.print(f"[bold green]Environment '{self.conda_env}' activated successfully![/]")
        else:
            self.console.print(f"[bold red]Failed to activate environment '{self.conda_env}'. Try running manually:[/]")
            self.console.print(f'    source "{conda_base}/etc/profile.d/conda.sh" && conda activate {self.conda_env}')


    def install_pytorch(self):
        """步骤6：安装PyTorch"""
        self.console.print(
            f"[bold {Color.CYAN.value}][Step 6] Installing PyTorch...[/]"
        )

        # 根据CUDA版本确定PyTorch索引
        cuda_map = {"11": "cu118", "12": "cu121"}
        self.pytorch_index_url = (
            f"https://download.pytorch.org/whl/{cuda_map[self.cuda_version]}"
        )

        torch_version = "2.5.1" if self.isaac_version == "2" else "2.4.0"
        self.run_cmd(
            f"conda run -n {self.conda_env} pip install torch=={torch_version} "
            f"--index-url {self.pytorch_index_url}",
            "Failed to install PyTorch",
        )

    def install_isaacsim(self):
        """安装IsaacSim"""
        self.console.print(
            f"[bold {Color.CYAN.value}]Installing IsaacSim...[/]"
        )

        version_map = {
            "1": "4.2.0.2",
            "2": "4.5.0"
        }
        packages = {
            "1": [
                "isaacsim==4.2.0.2",
                "isaacsim-extscache-physics==4.2.0.2",
                "isaacsim-extscache-kit==4.2.0.2",
                "isaacsim-extscache-kit-sdk==4.2.0.2",
            ],
            "2": ["isaacsim[all,extscache]==4.5.0"]
        }

        install_cmd = (
            f"conda run -n {self.conda_env} pip install --upgrade "
            f"{' '.join(packages[self.isaac_version])} "
            "--extra-index-url https://pypi.nvidia.com"
        )

        self.run_cmd(install_cmd, "Failed to install IsaacSim")

    def clone_isaaclab(self):
        """步骤8：克隆IsaacLab仓库"""
        self.console.print(
            f"[bold {Color.CYAN.value}][Step 8] Cloning IsaacLab repository...[/]"
        )

        # 获取路径
        path = inquirer.filepath(
            message="Enter project directory:",
            default=str(self.project_path),
            validate=PathValidator(is_dir=True),
            # style=self.styles["prompt"],
        ).execute()

        self.project_path = Path(path)
        repo_path = self.project_path / "IsaacLab"

        if repo_path.exists():
            choice = self.prompt_select(
                "Repository exists:",
                ["Pull latest", "Use existing", "Reclone"]
            )

            if choice == "Pull latest":
                self.run_cmd(f"git -C {repo_path} pull")
            elif choice == "Reclone":
                self.run_cmd(f"rm -rf {repo_path}")
                self.run_cmd(f"git clone https://github.com/isaac-sim/IsaacLab.git {repo_path}")
        else:
            self.run_cmd(f"git clone https://github.com/isaac-sim/IsaacLab.git {repo_path}")

        # 切换分支
        os.chdir(repo_path)
        if self.isaac_version == "1":
            self.run_cmd("git checkout v1.4.1")
        else:
            self.run_cmd("git checkout main")

    def verify_installation(self):
        """步骤10：验证安装"""
        self.console.print(
            f"[bold {Color.CYAN.value}][Step 10] Verifying installation...[/]"
        )

        if self.prompt_confirm("Run graphical verification?", default=True):
            test_script = (
                "scripts/tutorials/00_sim/create_empty.py"
                if self.isaac_version == "2"
                else "source/standalone/tutorials/00_sim/create_empty.py"
            )

            self.console.print(
                Panel.fit(
                    "When prompted, type 'Yes' to accept the NVIDIA Omniverse EULA",
                    title="EULA Notice",
                    style=Style(color="yellow", bold=True),
                )
            )

            self.run_cmd(
                f"conda run -n {self.conda_env} python {test_script}",
                "Verification failed"
            )

    # endregion

    def run_installation(self):
        """主安装流程"""
        try:
            self.print_header()

            # 用户选择版本
            self.isaac_version = self.prompt_select(
                "Select IsaacLab version:",
                [
                    {"name": "v1.4.1", "value": "1"},
                    {"name": "Latest v2.x.x", "value": "2"}
                ]
            )

            self.check_nvidia()
            self.check_cuda()
            self.check_glibc()
            self.manage_conda_env()
            self.install_pytorch()
            self.install_isaacsim()
            self.clone_isaaclab()
            self.verify_installation()

            # 最终输出
            self.console.print(
                Panel.fit(
                    f"Installation complete!\n"
                    f"Activate environment: [bold cyan]conda activate {self.conda_env}[/]\n"
                    f"Project directory: [bold cyan]{self.project_path}/IsaacLab[/]",
                    title="Success",
                    style=Style(color="green", bold=True),
                )
            )

        except Exception as e:
            self.console.print(
                Panel.fit(
                    f"Installation failed: {str(e)}",
                    title="Error",
                    style=Style(color="red", bold=True),
                )
            )
            sys.exit(1)


if __name__ == "__main__":
    IsaacInstaller().run_installation()