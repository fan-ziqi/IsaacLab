About Translation
=========================

原版英文文档网站： `https://isaac-sim.github.io/IsaacLab <https://isaac-sim.github.io/IsaacLab>`__ 

中文翻译文档网站： `https://docs.robotsfan.com/isaaclab <https://docs.robotsfan.com/isaaclab>`__ 

译者： `github@fan-ziqi <https://github.com/fan-ziqi>`__ 

翻译将在 `fan-ziqi/IsaacLab <https://github.com/fan-ziqi/IsaacLab>`__ 里更新。

如果你对此翻译有疑问，请联系 fanziqi614@gmail.com 或者在上述仓库开启一个issue。

如果您想参与翻译和校对工作，请阅读下述注意事项：

* 校对之前请在沟通群内声明自己将要校对的文件，以免重复工作。
* 拉取上述仓库并切换到 ``main`` 分支，并时刻确保你的本地分支与上游同步。
* 修改 ``docs/locale/zh_CN/LC_MESSAGES`` 中将要校对的 ``*.po`` 文件，然后开启pull-request。
* 如果上游文档有更新，使用正则表达式 ``(?<!#\n)#, fuzzy`` 找到变动的地方，校对后删除 ``#, fuzzy`` 行

**最后，感谢所有翻译校对参与者的无私奉献！**

更新日志：

* **2024-07-05** 使用正则表达式匹配特定位置并修复大部分错误格式；增加校对文档。 By `fan-ziqi <https://github.com/fan-ziqi>`__ 
* **2024-07-04** 使用Github-Action实现监测官方英文文档变化并自动触发增量翻译。自动构建HTML，上传到gh-pages-zhcn分支，并触发webhook自动同步到阿里云境内服务器，保证国内用户的访问速度。 By `fan-ziqi <https://github.com/fan-ziqi>`__ 
* **2024-07-03** 使用ChatGPT-3.5-API实现批量翻译脚本，对文档进行粗略翻译，但未翻译 ``API`` 和 ``CHANGELOG`` 。 By `fan-ziqi <https://github.com/fan-ziqi>`__ 
