#!/bin/bash

docker exec -it \
    bfmc_sim_container \
    sh -c 'source /opt/ros/melodic/setup.bash && \
           source ${SIMULATOR_WS}/devel/setup.bash && \
           source ${CONTROLLER_WS}/devel/setup.bash && \
           export PYTHONPATH=${SIMULATOR_WS}/devel/lib/python2.7/dist-packages:${PYTHONPATH} && \
           rosrun startup_package main.py'