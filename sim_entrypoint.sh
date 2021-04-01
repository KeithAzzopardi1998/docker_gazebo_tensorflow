#!/bin/bash

set -e

source /opt/ros/melodic/setup.bash
source ${SIMULATOR_WS}/devel/setup.bash

exec "$@"