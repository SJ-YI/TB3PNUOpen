# Project Background
This project is a modularized software framework for generic robot development and research. The modularized platform separates low level components that vary from robot to robot from the high level logic that does not vary across robots. The low level components include processes to communicate with motors and sensors on the robot, including the camera. The high level components include the state machines that control how the robots move around and process sensor data. By separating into these levels, we achieve a more adaptable system that is easily ported to different robots.

## Copyright

All code sources associated with this project are:

* (c) 2019 Seung-Joon Yi
* (c) 2020 Seung-Joon Yi
* (c) 2021 Seung-Joon Yi

* Exceptions are noted on a per file basis.

### Contact Information

* seungjoon.yi@pusan.ac.kr

# Ubuntu Setup

Download the 16.04.1 LTS desktop image from [Ubuntu](http://www.ubuntu.com/download/desktop)

### ROS Kinect install
```
sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
sudo apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
sudo apt-get update
sudo apt-get install ros-kinetic-desktop-full
apt-cache search ros-kinetic
sudo rosdep init
rosdep update
```

## Required Packages
```
sudo apt-get install swig tmux ros-kinetic-ar-track-alvar ros-kinetic-amcl ros-kinetic-move-base ros-kinetic-dwa-local-planner
```

### Clone main code
```
cd ~/Desktop
git clone https://github.com/SJ-YI/TB3PNUOpen.git
```

### Install Dependencies
```
cd ~/Desktop/TB3PNUOpen/Dependencies

tar xvf zeromq-3.2.5.tar.gz
cd zeromq-3.2.5
./configure
make
sudo make install PREFIX=/usr/local

cd ../luajit-2.0
make
sudo make install
sudo ln -sf luajit-2.1.0-beta2 /usr/local/bin/luajit
```

### Install webots simulator
```
cd ~/Download
wget https://github.com/cyberbotics/webots/releases/download/R2020b-rev1/webots-R2020b-rev1-x86-64_ubuntu-16.04.tar.bz2
tar xjf webots-R2020a-rev1-x86-64.tar.bz2
sudo ln -s ~/Downloads/webots /usr/local
sudo ln -s ~/Downloads/webots/webots /usr/local/bin
```

### Compile ros packages
```
cd ~/Desktop/TB3PNUOpen/catkin_ws
catkin_make
```

### Compile main code
```
cd ~/Desktop/TB3PNUOpen
sudo ldconfig
make -j4
```

### Edit .bashrc
```
echo "source /opt/ros/kinetic/setup.bash" >> ~/.bashrc
echo "source ~/Desktop/TB3PNUOpen/catkin_ws/devel/setup.bash" >> ~/.bashrc
```

### Run webots simulation for Turtlebot 3
```
cd ~/Desktop/TB3PNUOpen
./start_tb3_sim_1.sh
```

Press "i","j","k","l","," keys to move the robot around (in Webots simulator)

### Run webots simulation for Turtlebot 3 Service Robot
```
cd ~/Desktop/TB3PNUOpen
./start_granny_sim.sh
```

Press "i","j","k","l",",","h",";" keys to move the robot around
Press "1","2" keys to change arm position
press "[", "]" keys to open and close gripper
