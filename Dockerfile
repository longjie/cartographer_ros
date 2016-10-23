# Copyright 2016 The Cartographer Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM ros:indigo

# wstool needs the updated rosinstall file to clone the correct repos.
COPY cartographer_ros.rosinstall cartographer_ros/
COPY scripts/prepare_catkin_workspace.sh cartographer_ros/scripts/
# Remove the contents of the cartographer_ros repo and copy in the updated
# files as necessary.
RUN cartographer_ros/scripts/prepare_catkin_workspace.sh && \
    rm -rf catkin_ws/src/cartographer_ros/*

# rosdep needs the updated package.xml files to install the correct debs.
COPY cartographer_ros/package.xml catkin_ws/src/cartographer_ros/cartographer_ros/
COPY cartographer_ros_msgs/package.xml catkin_ws/src/cartographer_ros/cartographer_ros_msgs/
COPY cartographer_rviz/package.xml catkin_ws/src/cartographer_ros/cartographer_rviz/
COPY ceres_solver/package.xml catkin_ws/src/cartographer_ros/ceres_solver/
COPY scripts/install_debs.sh cartographer_ros/scripts/
RUN cartographer_ros/scripts/install_debs.sh && rm -rf /var/lib/apt/lists/*

# Build, install, and test all packages individually to allow caching.
COPY scripts/install.sh cartographer_ros/scripts/

COPY ceres_solver catkin_ws/src/cartographer_ros/
RUN cartographer_ros/scripts/install.sh --pkg ceres_solver

# This file's content changes whenever master changes. See:
# http://stackoverflow.com/questions/36996046/how-to-prevent-dockerfile-caching-git-clone
ADD https://api.github.com/repos/googlecartographer/cartographer/git/refs/heads/master \
    cartographer_ros/cartographer_version.json
RUN cartographer_ros/scripts/install.sh --pkg cartographer && \
    cartographer_ros/scripts/install.sh --pkg cartographer --make-args test

COPY cartographer_ros_msgs catkin_ws/src/cartographer_ros/
RUN cartographer_ros/scripts/install.sh --pkg cartographer_ros_msgs \
    --catkin-make-args run_tests

COPY cartographer_ros catkin_ws/src/cartographer_ros/
RUN cartographer_ros/scripts/install.sh --pkg cartographer_ros \
    --catkin-make-args run_tests

COPY cartographer_rviz catkin_ws/src/cartographer_ros/
RUN cartographer_ros/scripts/install.sh --pkg cartographer_rviz \
    --catkin-make-args run_tests

COPY scripts/ros_entrypoint.sh /
# A BTRFS bug may prevent us from cleaning up these directories.
# https://btrfs.wiki.kernel.org/index.php/Problem_FAQ#I_cannot_delete_an_empty_directory
RUN rm -rf cartographer_ros catkin_ws || true
