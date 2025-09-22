Welcome to Isaac Lab!
=====================

.. figure:: source/_static/isaaclab.jpg
   :width: 100%
   :alt: H1 Humanoid example using Isaac Lab


.. attention::

    本翻译项目不属于 NVIDIA 或 IsaacLab 官方文档，由 `范子琦 <https://github.com/fan-ziqi>`__ 提供中文翻译，仅供学习交流使用，禁止转载或用于商业用途。详情请查看 `关于翻译 <source/setup/translation.html>`_ 章节。

    **重要！！！本站将于9月中旬进行停机维护，恢复时间将在群内通知！！！**

    官方文档引入了版本系统，可以查看历史版本的文档。译者精力有限，故不提供历史版本翻译，本站只同步更新main分支的文档。

    由于1.x.x与2.2.xAPI差异较大，故本站保留了一版1.x.x版本的文档(不一定是最新的1.4.1，但不会差很多)，可以通过 `https://docs.robotsfan.com/isaaclab_v1 <https://docs.robotsfan.com/isaaclab_v1>`__ 访问。

    如果您需要基于IsaacLab开发您自己的独立拓展项目，请参考 `robot_lab <https://github.com/fan-ziqi/robot_lab>`__ 项目。

    如果您想将IsaacLab训练的模型部署到实际机器人上或在Gazebo中仿真，请参考 `rl_sar <https://github.com/fan-ziqi/rl_sar>`__ 项目。


**Isaac Lab** is a unified and modular framework for robot learning that aims to simplify common workflows
in robotics research (such as reinforcement learning, learning from demonstrations, and motion planning). It is built on
`NVIDIA Isaac Sim`_ to leverage the latest simulation capabilities for photo-realistic scenes, and fast
and efficient simulation.

The core objectives of the framework are:

- **Modularity**: Easily customize and add new environments, robots, and sensors.
- **Agility**: Adapt to the changing needs of the community.
- **Openness**: Remain open-sourced to allow the community to contribute and extend the framework.
- **Batteries-included**: Include a number of environments, sensors, and tasks that are ready to use.

Key features available in Isaac Lab include fast and accurate physics simulation provided by PhysX,
tiled rendering APIs for vectorized rendering, domain randomization for improving robustness and adaptability,
and support for running in the cloud.

Additionally, Isaac Lab provides a variety of environments, and we are actively working on adding more environments
to the list. These include classic control tasks, fixed-arm and dexterous manipulation tasks, legged locomotion tasks,
and navigation tasks. A complete list is available in the `environments <source/overview/environments>`_ section.

Isaac lab is developed with specific robot assets that are now **Batteries-included** as part of the platform and are ready to learn! These robots include...

- **Classic** Cartpole, Humanoid, Ant
- **Fixed-Arm and Hands**: UR10, Franka, Allegro, Shadow Hand
- **Quadrupeds**: Anybotics Anymal-B, Anymal-C, Anymal-D, Unitree A1, Unitree Go1, Unitree Go2, Boston Dynamics Spot
- **Humanoids**: Unitree H1, Unitree G1
- **Quadcopter**: Crazyflie

The platform is also designed so that you can add your own robots! Please refer to the
:ref:`how-to` section for details.

For more information about the framework, please refer to the `paper <https://arxiv.org/abs/2301.04195>`_
:cite:`mittal2023orbit`. For clarifications on NVIDIA Isaac ecosystem, please check out the
:ref:`isaac-lab-ecosystem` section.

.. figure:: source/_static/tasks.jpg
   :width: 100%
   :alt: Example tasks created using Isaac Lab


License
=======

The Isaac Lab framework is open-sourced under the BSD-3-Clause license,
with certain parts under Apache-2.0 license. Please refer to :ref:`license` for more details.

Acknowledgement
===============
Isaac Lab development initiated from the `Orbit <https://isaac-orbit.github.io/>`_ framework.
We would appreciate if you would cite it in academic publications as well:

.. code:: bibtex

   @article{mittal2023orbit,
      author={Mittal, Mayank and Yu, Calvin and Yu, Qinxi and Liu, Jingzhou and Rudin, Nikita and Hoeller, David and Yuan, Jia Lin and Singh, Ritvik and Guo, Yunrong and Mazhar, Hammad and Mandlekar, Ajay and Babich, Buck and State, Gavriel and Hutter, Marco and Garg, Animesh},
      journal={IEEE Robotics and Automation Letters},
      title={Orbit: A Unified Simulation Framework for Interactive Robot Learning Environments},
      year={2023},
      volume={8},
      number={6},
      pages={3740-3747},
      doi={10.1109/LRA.2023.3270034}
   }


Table of Contents
=================

.. toctree::
   :maxdepth: 1
   :caption: Isaac Lab

   source/setup/translation
   source/setup/wechat
   source/setup/oneclick_installation
   source/setup/ecosystem
   source/setup/installation/index
   source/deployment/index
   source/setup/installation/cloud_installation
   source/refs/reference_architecture/index


.. toctree::
   :maxdepth: 2
   :caption: Getting Started
   :titlesonly:

   source/setup/quickstart
   source/overview/own-project/index
   source/setup/walkthrough/index
   source/tutorials/index
   source/how-to/index
   source/overview/developer-guide/index


.. toctree::
   :maxdepth: 3
   :caption: Overview
   :titlesonly:


   source/overview/core-concepts/index
   source/overview/environments
   source/overview/reinforcement-learning/index
   source/overview/imitation-learning/index
   source/overview/showroom
   source/overview/simple_agents


.. toctree::
   :maxdepth: 2
   :caption: Features

   source/features/hydra
   source/features/multi_gpu
   source/features/population_based_training
   Tiled Rendering</source/overview/core-concepts/sensors/camera>
   source/features/ray
   source/features/reproducibility


.. toctree::
   :maxdepth: 3
   :caption: Experimental Features

   source/experimental-features/bleeding-edge
   source/experimental-features/newton-physics-integration/index

.. toctree::
   :maxdepth: 1
   :caption: Resources
   :titlesonly:

   source/setup/installation/cloud_installation
   source/policy_deployment/index

.. toctree::
   :maxdepth: 1
   :caption: Migration Guides
   :titlesonly:

   source/migration/migrating_from_isaacgymenvs
   source/migration/migrating_from_omniisaacgymenvs
   source/migration/migrating_from_orbit

.. toctree::
   :maxdepth: 1
   :caption: Source API

   source/api/index

.. toctree::
   :maxdepth: 1
   :caption: References


   source/refs/additional_resources
   source/refs/contributing
   source/refs/troubleshooting
   source/refs/migration
   source/refs/issues
   source/refs/release_notes
   source/refs/changelog
   source/refs/license
   source/refs/bibliography

.. toctree::
    :hidden:
    :caption: Project Links

    GitHub <https://github.com/isaac-sim/IsaacLab>
    NVIDIA Isaac Sim <https://docs.isaacsim.omniverse.nvidia.com/latest/index.html>
    NVIDIA PhysX <https://nvidia-omniverse.github.io/PhysX/physx/5.4.1/index.html>

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`

.. _NVIDIA Isaac Sim: https://docs.isaacsim.omniverse.nvidia.com/latest/index.html
