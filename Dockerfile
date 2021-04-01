FROM osrf/ros:melodic-desktop-full

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
#  pip install matplotlib && \
  pip install numpy && \
#  pip install scipy && \
#  pip install jupyter && \
#  pip install seaborn && \
#  pip install pandas && \
  pip install scikit-build && \
  pip install bokeh && \
  pip install vcstool && \
  pip install rosbag_pandas && \
  pip install opencv-python==4.2.0.32

EXPOSE 11345


COPY ./sim_entrypoint.sh /
RUN chmod +x /sim_entrypoint.sh

ENTRYPOINT ["/sim_entrypoint.sh"]

CMD ["bash"]