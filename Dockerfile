FROM tensorflow/tensorflow:2.1.0-gpu

#we should be using the ROS melodic image, but installing 
#tensorflow is not as straightforward. So instead, we start
#with the tensorflow image, and follow the dockerfiles to
#"rebuild" the image from scratch. The dockerfiles can be
#found at https://github.com/osrf/docker_images/tree/20e12ac5ff52ce5c38aaf5d0dbcf0256f124c3ba/ros/melodic/ubuntu/bionic

#the ROS melodic images are "stacked" on top of eachother
# 1 : core
RUN echo 'Etc/UTC' > /etc/timezone && \
    ln -s /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
    apt-get update && \
    apt-get install -q -y --no-install-recommends tzdata && \
    rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -q -y --no-install-recommends \
    dirmngr \
    gnupg2 \
    && rm -rf /var/lib/apt/lists/*
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
RUN echo "deb http://packages.ros.org/ros/ubuntu bionic main" > /etc/apt/sources.list.d/ros1-latest.list
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV ROS_DISTRO melodic
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-melodic-ros-core=1.4.1-0* \
    && rm -rf /var/lib/apt/lists/*

# 2 : base
RUN apt-get update && apt-get install --no-install-recommends -y \
    build-essential \
    python-rosdep \
    python-rosinstall \
    python-vcstools \
    && rm -rf /var/lib/apt/lists/*
RUN rosdep init && \
  rosdep update --rosdistro $ROS_DISTRO
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-melodic-ros-base=1.4.1-0* \
    && rm -rf /var/lib/apt/lists/*

# 3 : robot
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-melodic-robot=1.4.1-0* \
    && rm -rf /var/lib/apt/lists/*

# 4 : desktop
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-melodic-desktop=1.4.1-0* \
    && rm -rf /var/lib/apt/lists/*

# 5 : desktop-full
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-melodic-desktop-full=1.4.1-0* \
    && rm -rf /var/lib/apt/lists/*

# moving on, we can assume that we have a "combination" of the following two images:
# 1. tensorflow/tensorflow:2.1.0-gpu
# 2. osrf/ros:melodic-desktop-full

ENV NVIDIA_VISIBLE_DEVICES \
    ${NVIDIA_VISIBLE_DEVICES:-all}
ENV NVIDIA_DRIVER_CAPABILITIES \
    ${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}graphics

RUN apt-get update && apt-get install -y apt-utils build-essential psmisc vim-gtk

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN apt-get update && apt-get install -q -y python-catkin-tools

RUN apt-get update && apt-get install -q -y ros-melodic-hector-gazebo-plugins

# not sure if we need git-lfs
RUN echo 'deb http://http.debian.net/debian wheezy-backports main' > /etc/apt/sources.list.d/wheezy-backports-main.list
RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash
RUN apt-get install -q -y git-lfs
RUN git lfs install

# getting the code used to run the simulation
ENV MAIN_DIR=/simulator
ENV SIMULATOR_WS="${MAIN_DIR}/bfmc_workspace"
ENV CONTROLLER_WS="${MAIN_DIR}/startup_workspace"
RUN git clone https://github.com/KeithAzzopardi1998/BFMC_Simulator.git "${MAIN_DIR}"

WORKDIR ${SIMULATOR_WS}
RUN source /opt/ros/melodic/setup.bash && \
    catkin_make && \
    source devel/setup.bash

ENV GAZEBO_MODEL_PATH="${SIMULATOR_WS}/src/models_pkg:$GAZEBO_MODEL_PATH"
ENV ROS_PACKAGE_PATH="${SIMULATOR_WS}/src:$ROS_PACKAGE_PATH"

WORKDIR ${CONTROLLER_WS}
RUN source /opt/ros/melodic/setup.bash && \
    catkin_make && \
    source devel/setup.bash


# Required python packages
RUN \
  apt-get install -y python-pip && \
  python -m pip install --upgrade pip && \
  pip install numpy && \
  pip install scikit-build && \
  pip install bokeh && \
  pip install vcstool && \
  pip install rosbag_pandas && \
  pip install opencv-python==4.2.0.32 && \
  pip install tensorflow-gpu==2.1.0

EXPOSE 11345


COPY ./sim_entrypoint.sh /
RUN chmod +x /sim_entrypoint.sh

ENTRYPOINT ["/sim_entrypoint.sh"]

CMD ["bash"]
