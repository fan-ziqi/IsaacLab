【非官方】一键安装脚本
===============================

本脚本支持 Isaac Lab 多个版本的一键安装，可选择 **uv** （推荐）或 **conda** 。脚本使用 Bash，无需预先配置系统 Python。

快速开始
-----------------------------

从本站下载并运行：

.. code-block:: bash

   wget -O install_isaaclab.sh https://docs.robotsfan.com/install_isaaclab.sh && bash install_isaaclab.sh

或从 `Gist <https://gist.github.com/fan-ziqi/1388ffb9c853de731d970285e355d02c>`__ 下载：

.. code-block:: bash

   wget -O install_isaaclab.sh https://gist.githubusercontent.com/fan-ziqi/1388ffb9c853de731d970285e355d02c/raw/install_isaaclab.sh && bash install_isaaclab.sh

也可下载 :download:`安装脚本 <../../../install_isaaclab.sh>`，在下载目录运行 ``bash install_isaaclab.sh``。

支持版本
-----------------------------

.. list-table::
   :header-rows: 1
   :widths: 20 25 15 20 20

   * - Isaac Lab
     - Isaac Sim
     - Python
     - PyTorch
     - CUDA
   * - 3.0.0
     - |isaacsim_version| （可选）
     - 3.12
     - |torch_version|
     - cu130
   * - v2.3.2
     - 5.1.0
     - 3.11
     - 2.7.0
     - cu128
   * - v1.4.1
     - 4.2.0.2
     - 3.10
     - 2.4.0
     - cu118

3.0 对应 ``release/3.0.0`` 分支，可选择完整 Isaac Sim 工作流或仅安装 Newton。

特点
-----------------------------

* 自动检查 NVIDIA 驱动和 GLIBC 版本。
* 使用独立环境，支持多个版本并存。
* 交互式选择安装选项，并验证安装结果。

脚本仅适用于 Linux，系统和驱动要求请参阅 :doc:`官方安装指南 <installation/index>`。

安装流程
-----------------------------

1. 选择 Isaac Lab 版本、包管理器和安装目录（3.0 可选择后端）。
2. 检查系统依赖、NVIDIA 驱动和 GLIBC。
3. 创建独立环境，安装所选后端和 Isaac Lab 依赖。
4. 验证安装。

常见问题
-----------------------------

安装 v1.4.1 时，如遇到 ``No matching distribution found for rsl-rl``，请在下面的文件中，将依赖字符串开头的 ``rsl-rl@`` 改为 ``rsl-rl-lib@``，然后重新运行脚本：

.. code-block:: text

   source/extensions/omni.isaac.lab_tasks/setup.py

原帖： `Isaac Lab Discussion #1470 <https://github.com/isaac-sim/IsaacLab/discussions/1470>`__ 。
