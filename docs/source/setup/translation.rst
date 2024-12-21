【非官方】关于翻译
===============================

.. attention::

    本翻译项目不属于 NVIDIA 或 IsaacLab 官方文档，由 `范子琦 <https://github.com/fan-ziqi>`__ 提供中文翻译，仅供学习交流使用，禁止转载或用于商业用途。

    官方文档引入了版本系统，可以查看历史版本的文档。译者精力有限，故不提供历史版本翻译，本站只同步更新main分支的文档。

IsaacLab原版英文文档网站: `https://isaac-sim.github.io/IsaacLab <https://isaac-sim.github.io/IsaacLab>`__

IsaacLab中文翻译文档网站: `https://docs.robotsfan.com/isaaclab <https://docs.robotsfan.com/isaaclab>`__

IsaacSim中文文档网站（API自动翻译）: `https://docs.robotsfan.com/isaacsim <https://docs.robotsfan.com/isaacsim>`__

所有翻译均开源在 `fan-ziqi/IsaacLab <https://github.com/fan-ziqi/IsaacLab>`__ ，译者: `github@fan-ziqi <https://github.com/fan-ziqi>`__ 。如果你对此翻译项目有疑问，请通过 fanziqi614@gmail.com 联系译者。

.. note::

   随着本站用户的增多，轻量服务器访问负载日渐增加。如果您认可本站的工作，可以通过下面的赞赏码打赏。收到的赞赏用于托管本翻译网站服务器的续费和升级，感谢您的支持！

   赞赏名单: **H\*R** 、 **\*彡** 、 **b\*k** 、 **\*涛** 、 **\*航** 、 **\*靖** 、 **李\*坤** 、 **\*玉** 、 **胡\*泽** 、 **\*塔** 、 **王\*辉** 、 **\*崇**、 **\*熠***

   .. figure:: ../_static/thanks.png
      :width: 450px
      :align: center
      :alt: 赞赏码

翻译过程
-----------------------------

本翻译项目的第一个版本使用ChatGPT-3.5-API编写了批量翻译脚本，对文档进行粗略翻译，但未翻译 ``API`` 和 ``CHANGELOG`` 。使用Github-Action实时监测官方文档变化并自动触发增量翻译，自动构建HTML，上传到gh-pages-zhcn分支，并触发webhook自动同步到阿里云境内服务器，保证国内用户的访问速度。随着文档更新越来越频繁以及为了确保翻译准确，之后的更新均为作者手动翻译，不再大面积使用GPT辅助。

重建文档的步骤:

.. code-block:: bash

   # install python packages
   pip install setuptools polib==1.2.0 openai==v1.3.6 python-dotenv==1.0.0 pytest==8.2.2 sphinx-intl sphinx-book-theme==1.0.1 myst-parser sphinxcontrib-bibtex==2.5.0 autodocsumm sphinx-copybutton sphinx-icon sphinx_design sphinxemoji numpy matplotlib warp-lang gymnasium sphinx-tabs sphinx-multiversion==0.2.4
   # merge upstream changes
   git remote add upstream https://github.com/isaac-sim/IsaacLab.git
   git fetch upstream
   git merge upstream/main --strategy-option ours --allow-unrelated-histories --verbose
   # make pot files
   sphinx-build -M gettext . _build
   # make po files
   sphinx-intl update -p _build/gettext -l zh_CN
   # transtale to zh_CN
   python po_translator.py --folder ./locale --lang zh_CN --folder-language --bulk --fuzzy
   # make translated html files
   sphinx-build -M html . _build -D language='zh_CN'
   # open on default browser
   xdg-open _build/html/index.html

过程中还需要:

* 使用搜索 ``#, fuzzy`` 找到变动的地方，校对后删除 ``#, fuzzy`` 标志。
* 通过搜索 ``#~`` 找到并删除已废弃的翻译,使用正则表达式删除整行 ``^#~.*\n``

译者说
-----------------------------

绝大部分报错都可以在 `Linux Troubleshooting <https://docs.omniverse.nvidia.com/dev-guide/latest/linux-troubleshooting.html>`__ 中找到解决方案。下面补充一些官方文档中没有的解决方案:

如何更新？
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

如IsaacLab/IsaacSim有更新，pull最新的IsaacLab执行下述步骤即可解决。（仅限pip安装的Isaac系列）

.. code-block:: bash

   pip install --upgrade isaacsim-rl isaacsim-replicator isaacsim-extscache-physics isaacsim-extscache-kit-sdk isaacsim-extscache-kit isaacsim-app --extra-index-url https://pypi.nvidia.com
   ./isaaclab.sh --install


Ubuntu20.04使用pip安装Isaac Sim
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

使用pip安装Isaac Sim只支持 ``GLIBC>=2.34`` 。 `bug link <https://forums.developer.nvidia.com/t/isaac-sim-python-environment-installation-with-pip-through-conda/294913/12>`__ ，如果你使用的是Ubuntu20.04，使用 ``ldd --version`` 查看GLIBC版本，如果版本低于 ``2.34`` 则需要升级GLIBC。 请注意，升级GLIBC是一个危险操作可能会导致无法与其的问题，请谨慎升级！

首先在 ``/etc/apt/sources.list`` 中添加 ``deb http://th.archive.ubuntu.com/ubuntu jammy main``

.. code-block:: bash

   sudo apt update
   sudo apt install libc6

然后使用 ``ldd --version`` 查看升级后的GLIBC版本。

最后从 ``/etc/apt/sources.list`` 中删除 ``deb http://th.archive.ubuntu.com/ubuntu jammy main`` ，升级完成，可继续使用Pip进行安装。

通过pip安装的isaacsim打开后报错
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

报错类似如下:

.. code-block::

   [omni.isaac.sim.python-x.x.x] dependency: 'omni.isaac.xxx' = { version='^' } can't be satisfied.

这是因为Isaac Lab只安装RL所需的“Isaac Sim - Python packages”。安装完整版本的“Isaac Sim - Python packages”即可解决，这样您将安装所有扩展（与Isaac Lab 100%兼容）。

.. code-block:: bash

   pip install isaacsim --extra-index-url https://pypi.nvidia.com

需要升级的话加上 ``--upgrade`` 即可。

