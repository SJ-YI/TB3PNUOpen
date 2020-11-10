assert(Config, 'Need a pre-existing Config table!')
local vector = require'vector'


Config.sensors={
  imu=true,
  pose=true,
  head_lidar=true,
  kinect=true,
}
Config.lidar_crop=0 --crop 15 rays from left and right

Config.camera_timestep = 33
Config.kinect_timestep = 33
Config.lidar_timestep = 200

return Config
