sudo apt -y install swig git ros-kinetic-ar-track-alvar
sudo ldconfig

###############################################################################################################3
## Install ROS
echo "Detecting ROS kinetic..."
if test -f "/opt/ros/kinetic/setup.bash"; then
  echo "ROS kinetic detected!"
else
  echo "ROS kinetic not detected, installing..."
  sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
  sudo apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
  sudo apt-get update
  sudo apt-get -y install ros-kinetic-desktop-full
  apt-cache search ros-kinetic
  sudo rosdep init
  rosdep update
  source /opt/ros/kinetic/setup.bash
  echo 'source /opt/ros/kinetic/setup.bash' >> ~/.bashrc
  echo 'export ROS_DIR=/opt/ros/kinetic' >> ~/.bashrc
fi
###############################################################################################################3

###############################################################################################################3
## Install luajit
if test -f "/usr/local/bin/luajit"; then
  echo "Luajit already installed, skipping"
else
  echo "Luajit not detected, installing..."
  cd ~/Desktop/TurtleBotPNU/Dependencies/luajit-2.0
  make
  sudo make install
  sudo ln -sf luajit-2.1.0-beta2 /usr/local/bin/luajit
fi
###############################################################################################################3

###############################################################################################################3
## Install ZMQ
if test -f "/home/sj/Desktop/TurtleBotPNU/Dependencies/zeromq-3.2.5/Makefile"; then
  echo "ZMQ already installed, skipping"
else
  echo "ZMQ not detected, installing..."
  cd ~/Desktop/ARAICodes/Dependencies
  tar -xf zeromq-3.2.5.tar.gz
  cd zeromq-3.2.5
  ./configure
  make
  sudo make install PREFIX=/usr/local
fi
###############################################################################################################

###############################################################################################################3
## Install webots
if test -f "/usr/local/webots"; then
  echo "Webots already installed, skipping"
else
  echo "Webots not detected, installing..."
  cd ~/Download
  wget https://github.com/cyberbotics/webots/releases/download/R2020a-rev1/webots-R2020a-rev1-x86-64.tar.bz2
  tar xjf webots-R2020a-rev1-x86-64.tar.bz2
  sudo ln -s ~/Downloads/webots /usr/local
  sudo ln -s ~/Downloads/webots/webots /usr/local/bin
fi
###############################################################################################################3

###############################################################################################################3
## Compile code
cd ~/Desktop/TurtleBotPNU
source ~/.bashrc
sudo ldconfig
make -j4
cd ~/Desktop/TurtleBotPNU/catkin_ws
catkin_make
echo 'source /home/sj/Desktop/TurtleBotPNU/catkin_ws/devel/setup.bash' >> ~/.bashrc
##
###############################################################################################################
