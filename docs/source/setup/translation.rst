About Translation
=========================

**本翻译项目不属于 NVIDIA 官方文档，仅供学习交流使用。**

原版英文文档网站： `https://isaac-sim.github.io/IsaacLab <https://isaac-sim.github.io/IsaacLab>`__ 

中文翻译文档网站： `https://docs.robotsfan.com/isaaclab <https://docs.robotsfan.com/isaaclab>`__ 

翻译开源在 `fan-ziqi/IsaacLab <https://github.com/fan-ziqi/IsaacLab>`__ ，译者： `github@fan-ziqi <https://github.com/fan-ziqi>`__ 。

.. note::

   随着本站用户的日渐增多，轻量服务器已经承受不住如此大的访问负载。如您认可本站的工作，可以通过下面的赞赏码打赏。收到的赞赏均用于服务器升级，如有剩余将用于公益救助事业，感谢您的支持！

   赞赏名单： **H\*R** 、 **\*彡** 、 **b\*k** 、 **\*涛** 、 **\*航** 、 **\*靖** 、 **李\*坤** 、 **\*玉** 、 **胡\*泽** 、 **\*塔**

   .. figure:: ../_static/thanks.png
      :width: 450px
      :align: center
      :alt: 赞赏码

参与翻译
-----------------------------

如果你对此翻译有疑问，请通过 fanziqi614@gmail.com 联系译者或在 `fan-ziqi/IsaacLab <https://github.com/fan-ziqi/IsaacLab>`__ 开启一个issue。

如果您想参与翻译和校对工作，请阅读下述注意事项：

* 校对之前请在沟通群内声明自己将要校对的文件，以免重复工作。
* 拉取上述仓库并切换到 ``main`` 分支，并时刻确保你的本地分支与上游同步。
* 修改 ``docs/locale/zh_CN/LC_MESSAGES`` 中存在问题的 ``*.po`` 文件。
* 如果上游文档有更新，使用正则表达式 ``(?<!#\n)#, fuzzy`` 找到变动的地方，校对后删除 ``#, fuzzy`` 行。
* 通过搜索 ``#~`` 找到并删除已废弃的翻译。
* 改动后开启pull-request。

重建文档的步骤:

.. code-block:: bash

   # install python packages
   pip install setuptools polib==1.2.0 openai==v1.3.6 python-dotenv==1.0.0 pytest==8.2.2 sphinx-intl sphinx-book-theme==1.0.1 myst-parser sphinxcontrib-bibtex==2.5.0 autodocsumm sphinx-copybutton sphinx-icon sphinx_design sphinxemoji numpy matplotlib warp-lang gymnasium
   # merge upstream changes
   git remote add upstream https://github.com/isaac-sim/IsaacLab.git
   git fetch upstream
   git merge upstream/main --strategy-option ours --allow-unrelated-histories --verbose
   # make pot files
   make gettext
   # make po files
   sphinx-intl update -p _build/gettext -l zh_CN
   # transtale to zh_CN
   python po_translator.py --folder ./locale --lang zh_CN --folder-language --fuzzy
   # make translated html files
   make -e SPHINXOPTS="-D language='zh_CN'" html
   # open on default browser
   xdg-open _build/html/index.html

**最后，感谢所有翻译校对参与者的无私奉献！**

更新日志
-----------------------------

* **2024-08-25** 多处内容更新，多处格式校正。 By `fan-ziqi <https://github.com/fan-ziqi>`__ 
* **2024-08-07** 自动merge有问题，改为定期手动同步。 By `fan-ziqi <https://github.com/fan-ziqi>`__ 
* **2024-07-30** 修复了很多格式及翻译问题，增加赞赏码。 By `fan-ziqi <https://github.com/fan-ziqi>`__ 
* **2024-07-27** 同步文档至v1.1.0。 By `fan-ziqi <https://github.com/fan-ziqi>`__ 
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
