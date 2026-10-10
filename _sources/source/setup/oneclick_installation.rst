【非官方】一键安装脚本
===============================

本脚本支持 Isaac Lab ``release/3.0.0``，也保留 v2.3.2 和 v1.4.1 的安装入口。支持 **uv** 和 **conda**，在独立环境中安装，不改动系统 Python。

.. note::

   脚本适用于 Linux。安装 3.0 时，请先准备 Ubuntu 22.04 或更新版本及 NVIDIA GPU 驱动。CUDA 13.0 需要驱动版本不低于 ``580.65.06``，推荐版本和硬件要求见 :doc:`installation/index`。脚本会检查 GLIBC 和驱动；无需提前安装 CUDA Toolkit 或 ``nvcc``，也不会修改系统软件源或升级 GLIBC。

   3.0 支持 Linux x86_64 和 aarch64，旧版入口仅支持 x86_64。aarch64 所需的编译依赖和 DGX Spark 驱动要求，请先按官方安装指南准备。

支持的版本
-----------------------------

.. list-table::
   :header-rows: 1
   :widths: 20 25 15 40

   * - Isaac Lab
     - 上游分支或标签
     - Python
     - 安装内容
   * - 3.0.0
     - ``release/3.0.0``
     - 3.12
     - Newton；可选完整 Isaac Sim 6.1 工作流
   * - 2.3.2
     - ``v2.3.2``
     - 3.11
     - Isaac Sim 5.1.0、PyTorch 2.7.0、cu128
   * - 1.4.1
     - ``v1.4.1``
     - 3.10
     - Isaac Sim 4.2.0.2、PyTorch 2.4.0、cu118

3.0 的 PyTorch、Isaac Sim 和其他依赖版本由上游仓库的配置确定。``uv`` 安装使用 ``uv sync``；``conda`` 安装调用所选版本的官方安装器，避免将旧版依赖套用到 3.0。

使用方法
-----------------------------

在本翻译项目的仓库根目录执行：

.. code-block:: bash

   bash install_isaaclab.sh

脚本会依次询问版本、包管理器和安装目录。3.0 还可以选择完整 Isaac Sim 工作流，或仅安装 Newton。启动脚本会在缺少 ``uv`` 时安装它，再运行同目录下的 ``install.py``。

也可以下载 :download:`install.py <../../../install.py>`，安装 `uv <https://docs.astral.sh/uv/getting-started/installation/>`__ 后，在下载目录运行：

.. code-block:: bash

   uv run --no-project --no-config --script install.py

如果只下载 :download:`Bash 启动脚本 <../../../install_isaaclab.sh>`，启动脚本会从本项目的 GitHub ``main`` 分支下载 ``install.py``。离线审阅或尚未发布的修改，请使用仓库中的脚本，或将两个文件放在同一目录。

也可通过参数直接指定安装选项：

.. code-block:: bash

   # 3.0：完整 Isaac Sim 工作流
   bash install_isaaclab.sh --version 3.0.0 --manager uv \
      --backend isaacsim --directory "$PWD/IsaacLab-3.0"

   # 3.0：Newton，不安装 Isaac Sim
   bash install_isaaclab.sh --version 3.0.0 --manager uv \
      --backend newton --directory "$PWD/IsaacLab-3.0-newton"

   # 3.0：使用 Conda 环境
   bash install_isaaclab.sh --version 3.0.0 --manager conda \
      --backend isaacsim --env-name isaaclab_3_0 --directory "$PWD/IsaacLab-3.0-conda"

   # 查看安装命令，保留现有目录和环境
   uv run --no-project --no-config --script install.py --version 3.0.0 \
      --manager uv --backend isaacsim --directory "$PWD/IsaacLab-3.0" --dry-run

``--directory`` 指定的是 Isaac Lab 仓库的安装目录。已有仓库必须没有未提交的修改，脚本才会切换到所选上游版本；已有环境的 Python 版本必须匹配。脚本不会删除仓库或环境，不满足条件时会停止并提示原因。

安装完成后
-----------------------------

脚本会检查 3.0 的 ``isaaclab --help`` 命令行入口。完整仿真还需要可用的 GPU、图形环境及任务资源，安装后可按 :doc:`quickstart` 运行示例。首次启动 Isaac Sim 时，需要自行阅读并确认 NVIDIA 的许可协议。

使用 ``uv`` 安装完整 Isaac Sim 工作流后，后续命令仍需带上 ``--extra isaacsim``，例如：

.. code-block:: bash

   cd IsaacLab-3.0
   uv run --extra isaacsim isaaclab zero_agent \
      --task Isaac-Cartpole-Direct physics=isaacsim_physx --num_envs 16

仅安装 Newton 时，可以在对应目录运行：

.. code-block:: bash

   uv run isaaclab zero_agent --task Isaac-Cartpole-Direct \
      physics=newton_mjwarp --num_envs 16 --viz newton

使用 ``conda`` 时，先执行 ``conda activate isaaclab_3_0``，再运行 ``isaaclab`` 命令。

常见问题
-----------------------------

安装 v1.4.1 时，如遇到 ``No matching distribution found for rsl-rl``，可在下列文件中，将依赖字符串开头的 ``rsl-rl@`` 改为 ``rsl-rl-lib@``，然后重试安装：

.. code-block:: text

   source/extensions/omni.isaac.lab_tasks/setup.py

这一修正仅适用于旧版，不应套用到 Isaac Lab 3.0。
