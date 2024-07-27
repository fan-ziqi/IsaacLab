About Translation
=========================

原版英文文档网站： `https://isaac-sim.github.io/IsaacLab <https://isaac-sim.github.io/IsaacLab>`__ 

中文翻译文档网站： `https://docs.robotsfan.com/isaaclab <https://docs.robotsfan.com/isaaclab>`__ 

翻译开源在 `fan-ziqi/IsaacLab <https://github.com/fan-ziqi/IsaacLab>`__ ，译者： `github@fan-ziqi <https://github.com/fan-ziqi>`__ 。

参与翻译
-----------------------------

如果你对此翻译有疑问，请通过 fanziqi614@gmail.com 联系译者或在 `fan-ziqi/IsaacLab <https://github.com/fan-ziqi/IsaacLab>`__ 开启一个issue。

如果您想参与翻译和校对工作，请阅读下述注意事项：

* 校对之前请在沟通群内声明自己将要校对的文件，以免重复工作。
* 拉取上述仓库并切换到 ``main`` 分支，并时刻确保你的本地分支与上游同步。
* 修改 ``docs/locale/zh_CN/LC_MESSAGES`` 中将要校对的 ``*.po`` 文件，然后开启pull-request。
* 如果上游文档有更新，使用正则表达式 ``(?<!#\n)#, fuzzy`` 找到变动的地方，校对后删除 ``#, fuzzy`` 行
* 通过搜索 ``#~`` 找到并删除已废弃的翻译。

**最后，感谢所有翻译校对参与者的无私奉献！**

更新日志
-----------------------------

* **2024-07-23** 大部分格式问题均已修复，增加 **译者说** 。 By `fan-ziqi <https://github.com/fan-ziqi>`__ 
* **2024-07-05** 使用正则表达式匹配特定位置并修复大部分错误格式；增加校对文档。 By `fan-ziqi <https://github.com/fan-ziqi>`__ 
* **2024-07-04** 使用Github-Action实现监测官方英文文档变化并自动触发增量翻译。自动构建HTML，上传到gh-pages-zhcn分支，并触发webhook自动同步到阿里云境内服务器，保证国内用户的访问速度。 By `fan-ziqi <https://github.com/fan-ziqi>`__ 
* **2024-07-03** 使用ChatGPT-3.5-API实现批量翻译脚本，对文档进行粗略翻译，但未翻译 ``API`` 和 ``CHANGELOG`` 。 By `fan-ziqi <https://github.com/fan-ziqi>`__ 

译者说
-----------------------------

绝大部分报错都可以在 `Linux Troubleshooting <https://docs.omniverse.nvidia.com/dev-guide/latest/linux-troubleshooting.html>`__ 中找到解决方案。

下面补充一些官方文档中没有的解决方案：

Ubuntu20.04使用pip安装Isaac Sim
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

使用pip安装Isaac Sim只支持 ``GLIBC>=2.34`` 。 `bug link <https://forums.developer.nvidia.com/t/isaac-sim-python-environment-installation-with-pip-through-conda/294913/12>`__ ，如果你使用的是Ubuntu20.04，使用 ``ldd --version`` 查看GLIBC版本，如果版本低于 ``2.34`` 则需要升级GLIBC。 请注意，升级GLIBC是一个危险操作可能会导致无法与其的问题，请谨慎升级！

首先在 ``/etc/apt/sources.list`` 中添加 ``deb http://th.archive.ubuntu.com/ubuntu jammy main`` 

.. code-block:: bash

   sudo apt update
   sudo apt install libc6

然后使用 ``ldd --version`` 查看升级后的GLIBC版本。

最后从 ``/etc/apt/sources.list`` 中删除 ``deb http://th.archive.ubuntu.com/ubuntu jammy main`` ，升级完成，可继续使用Pip进行安装。

No module named 'xxx'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

如遇到IsaacLab/IsaacSim更新后无法找到某些包，pull最新的IsaacLab重新执行下述步骤即可解决。（仅限pip安装的Isaac系列）

.. code-block:: bash

   pip install --upgrade isaacsim-rl isaacsim-replicator isaacsim-extscache-physics isaacsim-extscache-kit-sdk isaacsim-extscache-kit isaacsim-app --extra-index-url https://pypi.nvidia.com
   ./isaaclab.sh --install