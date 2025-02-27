【非官方】一键安装脚本(pip)
===============================

本脚本同时支持v1.4.1和v2.x.x版本。在终端中执行以下命令：

.. code-block:: bash

   wget -O install_isaaclab.sh https://docs.robotsfan.com/install_isaaclab.sh && bash install_isaaclab.sh


常见问题
-----------------------------

安装v1.4.1版本时，如遇到 ``No matching distribution found for rsl-rl`` 错误，将 ``source/extensions/omni.isaac.lab_tasks/setup.py`` 第46行的 ``"rsl-rl": ["rsl-rl@`` 改成 ``"rsl-rl": ["rsl-rl-lib@`` ，然后重新执行安装脚本即可解决。