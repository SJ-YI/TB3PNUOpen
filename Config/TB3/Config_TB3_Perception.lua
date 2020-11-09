assert(Config, 'Need a pre-existing Config table!')
local vector = require'vector'

if ROBOT_TYPE=="0" then --Turtlebot
  Config.sensors={
    imu=true,
    pose=true,
  	--front_camera = true,
    head_lidar=true,
    kinect=true,
  }
  Config.lidar_crop=0 --crop 15 rays from left and right
else --Mecanum turtlebot
  Config.sensors={
    imu=true,
    pose=true,
    front_camera = true,
    head_lidar=true,
  }
  Config.camera={
    offset={0.045, 0, 0.125},
    angle=19*DEG_TO_RAD,
    fov = 1.02,
    xoffset=0.0,
    yoffset=0.0
  }
  Config.lidar_crop=20 --crop 15 rays from left and right
end

Config.camera_timestep = 33
Config.kinect_timestep = 33
Config.lidar_timestep = 200

return Config
