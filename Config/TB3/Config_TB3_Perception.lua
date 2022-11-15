assert(Config, 'Need a pre-existing Config table!')
local vector = require'vector'

if ROBOT_TYPE=="1" or ROBOT_TYPE=="2" then
  Config.sensors={
    imu=true,
    pose=true,
    head_lidar=true,
    kinect=true,
  }
else
  Config.sensors={
    imu=true,
    pose=true,
    head_lidar=false,
    kinect=true,
  }
end
Config.lidar_crop=0 --crop 15 rays from left and right

Config.camera_timestep = 33
Config.kinect_timestep = 33
Config.lidar_timestep = 200

return Config
