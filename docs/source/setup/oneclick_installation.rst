【非官方】一键安装脚本
===============================

本脚本支持以下 IsaacLab 版本的一键安装：

- v1.4.1 (IsaacSim 4.2.0.2, Python 3.10, PyTorch 2.4.0, cu118)
- v2.3.2 (IsaacSim 5.1.0, Python 3.11, PyTorch 2.7.0, cu128)
- main (IsaacSim 5.1.0, Python 3.11, PyTorch 2.7.0, cu128)
- develop (IsaacSim 6.0.0, Python 3.12, PyTorch 2.10.0, cu128)

支持 **uv** 和 **conda** 两种包管理器，安装过程中可选择。

在终端中执行以下命令：

.. code-block:: bash

   wget -O install_isaaclab.sh https://docs.robotsfan.com/install_isaaclab.sh && bash install_isaaclab.sh

脚本会依次完成以下步骤：

1. 选择 IsaacLab 版本
2. 选择包管理器（uv / conda）
3. 检查系统依赖、NVIDIA 驱动、GLIBC 版本
4. 安装并配置包管理器，创建虚拟环境
5. 安装 IsaacSim 和 PyTorch
6. 克隆 IsaacLab 仓库并安装依赖
7. 验证安装

常见问题
-----------------------------

安装v1.4.1版本时，如遇到 ``No matching distribution found for rsl-rl`` 错误，将 ``source/extensions/omni.isaac.lab_tasks/setup.py`` 第46行的 ``"rsl-rl": ["rsl-rl@`` 改成 ``"rsl-rl": ["rsl-rl-lib@`` ，然后重新执行安装脚本即可解决。
